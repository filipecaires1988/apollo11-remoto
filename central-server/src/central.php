<?php
declare(strict_types=1);

final class ApiError extends RuntimeException
{
    public function __construct(public readonly int $status, string $message)
    {
        parent::__construct($message);
    }
}

function central_database(string $path): PDO
{
    $db = new PDO('sqlite:' . $path, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $db->exec('PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000');
    return $db;
}

function central_schema(PDO $db): void
{
    $db->exec(<<<'SQL'
CREATE TABLE IF NOT EXISTS groups (id TEXT PRIMARY KEY, name TEXT NOT NULL COLLATE NOCASE UNIQUE);
CREATE TABLE IF NOT EXISTS devices (
    id TEXT PRIMARY KEY, group_id TEXT NOT NULL REFERENCES groups(id), name TEXT NOT NULL,
    peer_id TEXT NOT NULL, platform TEXT NOT NULL, token_hash TEXT UNIQUE,
    last_seen INTEGER, revoked_at INTEGER
);
CREATE UNIQUE INDEX IF NOT EXISTS active_peer_id ON devices(peer_id) WHERE revoked_at IS NULL;
CREATE TRIGGER IF NOT EXISTS groups_limit BEFORE INSERT ON groups
WHEN (SELECT COUNT(*) FROM groups) >= 500 BEGIN SELECT RAISE(ABORT, 'group limit'); END;
CREATE TRIGGER IF NOT EXISTS devices_limit BEFORE INSERT ON devices
WHEN NEW.revoked_at IS NULL AND (SELECT COUNT(*) FROM devices WHERE revoked_at IS NULL) >= 5000
BEGIN SELECT RAISE(ABORT, 'device limit'); END;
CREATE TABLE IF NOT EXISTS invites (
    code_hash TEXT PRIMARY KEY, group_id TEXT NOT NULL REFERENCES groups(id),
    expires_at INTEGER NOT NULL, used_at INTEGER
);
CREATE TABLE IF NOT EXISTS admin_sessions (token_hash TEXT PRIMARY KEY, expires_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS rate_limits (
    scope TEXT NOT NULL, identity TEXT NOT NULL, window INTEGER NOT NULL, count INTEGER NOT NULL,
    PRIMARY KEY(scope, identity)
);
SQL);
}

final class CentralApi
{
    public function __construct(private readonly PDO $db, private readonly string $passwordHash,
        private readonly string $sourceUrl = 'https://github.com/filipecaires1988/apollo11-remoto/tree/apollo11-central')
    {
    }

    private function query(string $sql, array $params = []): PDOStatement
    {
        $statement = $this->db->prepare($sql);
        $statement->execute($params);
        return $statement;
    }

    private function text(array $body, string $key, int $maximum = 120): string
    {
        $value = $body[$key] ?? null;
        if (!is_string($value) || trim($value) === '' || strlen($value) > $maximum || preg_match('/[\x00-\x1f\x7f]/', $value)) {
            throw new ApiError(422, 'Campo inválido: ' . $key . '.');
        }
        return trim($value);
    }

    private function peer(array $body): string
    {
        $value = $this->text($body, 'peer_id', 32);
        if (!preg_match('/^[0-9]{6,16}$/D', $value)) {
            throw new ApiError(422, 'Informe um ID de acesso remoto válido, somente com números.');
        }
        return $value;
    }

    private function platform(array $body): string
    {
        $value = $this->text($body, 'platform', 16);
        if (!in_array($value, ['Windows', 'macOS'], true)) {
            throw new ApiError(422, 'Sistema operacional inválido.');
        }
        return $value;
    }

    private function group(string $id): array
    {
        $group = $this->query('SELECT id, name FROM groups WHERE id = ?', [$id])->fetch(PDO::FETCH_ASSOC);
        if (!$group) {
            throw new ApiError(404, 'Cliente não encontrado.');
        }
        return $group;
    }

    private function device(string $id): array
    {
        $device = $this->query('SELECT id, group_id, name, peer_id, platform, last_seen FROM devices WHERE id = ? AND revoked_at IS NULL', [$id])->fetch(PDO::FETCH_ASSOC);
        if (!$device) {
            throw new ApiError(404, 'Computador não encontrado.');
        }
        $device['last_seen'] = $device['last_seen'] === null ? null : self::date((int) $device['last_seen']);
        $device['revoked'] = false;
        return $device;
    }

    private static function date(int $timestamp): string
    {
        return gmdate('Y-m-d\TH:i:s\Z', $timestamp);
    }

    private function admin(string $token): void
    {
        if (strlen($token) !== 64 || !$this->query('SELECT 1 FROM admin_sessions WHERE token_hash = ? AND expires_at > ?', [hash('sha256', $token), time()])->fetchColumn()) {
            throw new ApiError(401, 'Entre novamente na central.');
        }
    }

    private function rate(string $scope, string $identity, int $limit, int $period): void
    {
        $window = intdiv(time(), $period);
        $this->query('INSERT INTO rate_limits(scope, identity, window, count) VALUES (?, ?, ?, 1)
            ON CONFLICT(scope, identity) DO UPDATE SET window = excluded.window,
            count = CASE WHEN rate_limits.window = excluded.window THEN rate_limits.count + 1 ELSE 1 END',
            [$scope, hash('sha256', $identity), $window]);
        $count = (int) $this->query('SELECT count FROM rate_limits WHERE scope = ? AND identity = ?', [$scope, hash('sha256', $identity)])->fetchColumn();
        if ($count > $limit) {
            throw new ApiError(429, 'Muitas tentativas. Aguarde alguns minutos.');
        }
    }

    public function dispatch(string $method, string $route, array $body, string $token, string $ip): array
    {
        try {
            return $this->handle($method, $route, $body, $token, $ip);
        } catch (PDOException $error) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            if ($error->getCode() === '23000') {
                throw new ApiError(409, 'Este nome ou ID já está cadastrado, ou a central atingiu o limite de cadastros.');
            }
            throw $error;
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $error;
        }
    }

    private function handle(string $method, string $route, array $body, string $token, string $ip): array
    {
        if ($route === '/v1/source' && $method === 'GET') {
            return ['source_url' => $this->sourceUrl, 'license' => 'AGPL-3.0'];
        }
        if ($route === '/v1/admin/login' && $method === 'POST') {
            $this->rate('login', $ip, 10, 900);
            $password = $body['password'] ?? null;
            if (!is_string($password) || strlen($password) > 72 || str_contains($password, "\0") || !password_verify($password, $this->passwordHash)) {
                throw new ApiError(401, 'Senha incorreta.');
            }
            $token = bin2hex(random_bytes(32));
            $expiry = time() + 28800;
            $this->query('DELETE FROM admin_sessions WHERE expires_at <= ?', [time()]);
            $this->query('DELETE FROM rate_limits WHERE window < ?', [intdiv(time(), 900) - 96]);
            $this->query('INSERT INTO admin_sessions(token_hash, expires_at) VALUES (?, ?)', [hash('sha256', $token), $expiry]);
            return ['token' => $token, 'expires_at' => self::date($expiry)];
        }

        if ($route === '/v1/enroll' && $method === 'POST') {
            $this->rate('enroll', $ip, 20, 900);
            $code = $this->text($body, 'code', 128);
            $name = $this->text($body, 'name');
            $peer = $this->peer($body);
            $platform = $this->platform($body);
            $this->db->beginTransaction();
            $claim = $this->query('UPDATE invites SET used_at = ? WHERE code_hash = ? AND used_at IS NULL AND expires_at > ?', [time(), hash('sha256', $code), time()]);
            if ($claim->rowCount() !== 1) {
                throw new ApiError(401, 'Convite inválido, usado ou vencido.');
            }
            $invite = $this->query('SELECT group_id FROM invites WHERE code_hash = ?', [hash('sha256', $code)])->fetch(PDO::FETCH_ASSOC);
            $group = $this->group($invite['group_id']);
            $deviceId = bin2hex(random_bytes(16));
            $deviceToken = bin2hex(random_bytes(32));
            $this->query('INSERT INTO devices(id, group_id, name, peer_id, platform, token_hash, last_seen) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [$deviceId, $group['id'], $name, $peer, $platform, hash('sha256', $deviceToken), time()]);
            $this->db->commit();
            return ['device_id' => $deviceId, 'device_token' => $deviceToken, 'group_name' => $group['name']];
        }

        if ($route === '/v1/heartbeat' && $method === 'POST') {
            if (strlen($token) !== 64) {
                throw new ApiError(401, 'Vínculo revogado ou inválido.');
            }
            $peer = $this->peer($body);
            $platform = isset($body['platform']) ? $this->platform($body) : null;
            $result = $this->query('UPDATE devices SET last_seen = ?, peer_id = ?, platform = COALESCE(?, platform) WHERE token_hash = ? AND revoked_at IS NULL',
                [time(), $peer, $platform, hash('sha256', $token)]);
            if ($result->rowCount() !== 1) {
                throw new ApiError(401, 'Vínculo revogado ou inválido.');
            }
            return ['ok' => true];
        }

        $this->admin($token);
        if ($route === '/v1/admin/logout' && $method === 'POST') {
            $this->query('DELETE FROM admin_sessions WHERE token_hash = ?', [hash('sha256', $token)]);
            return ['ok' => true];
        }
        if ($route === '/v1/groups') {
            if ($method === 'GET') {
                return ['groups' => $this->query('SELECT id, name FROM groups ORDER BY name COLLATE NOCASE')->fetchAll(PDO::FETCH_ASSOC)];
            }
            if ($method === 'POST') {
                $id = bin2hex(random_bytes(16));
                $this->query('INSERT INTO groups(id, name) VALUES (?, ?)', [$id, $this->text($body, 'name')]);
                return ['group' => $this->group($id)];
            }
        }
        if (preg_match('#^/v1/groups/([a-f0-9]{32})$#D', $route, $matches)) {
            $id = $matches[1];
            $this->group($id);
            if ($method === 'PATCH') {
                $this->query('UPDATE groups SET name = ? WHERE id = ?', [$this->text($body, 'name'), $id]);
                return ['group' => $this->group($id)];
            }
            if ($method === 'DELETE') {
                $this->db->beginTransaction();
                if ($this->query('SELECT 1 FROM devices WHERE group_id = ? AND revoked_at IS NULL LIMIT 1', [$id])->fetchColumn()) {
                    throw new ApiError(409, 'Remova ou mova os computadores deste cliente primeiro.');
                }
                $this->query('DELETE FROM invites WHERE group_id = ?', [$id]);
                $this->query('DELETE FROM devices WHERE group_id = ? AND revoked_at IS NOT NULL', [$id]);
                $this->query('DELETE FROM groups WHERE id = ?', [$id]);
                $this->db->commit();
                return ['ok' => true];
            }
        }
        if ($route === '/v1/devices') {
            if ($method === 'GET') {
                $ids = $this->query('SELECT id FROM devices WHERE revoked_at IS NULL ORDER BY name COLLATE NOCASE')->fetchAll(PDO::FETCH_COLUMN);
                return ['devices' => array_map(fn(string $id): array => $this->device($id), $ids)];
            }
            if ($method === 'POST') {
                $groupId = $this->text($body, 'group_id', 32);
                $this->group($groupId);
                $id = bin2hex(random_bytes(16));
                $this->query('INSERT INTO devices(id, group_id, name, peer_id, platform) VALUES (?, ?, ?, ?, ?)',
                    [$id, $groupId, $this->text($body, 'name'), $this->peer($body), $this->platform($body)]);
                return ['device' => $this->device($id)];
            }
        }
        if (preg_match('#^/v1/devices/([a-f0-9]{32})$#D', $route, $matches)) {
            $id = $matches[1];
            $device = $this->device($id);
            if ($method === 'PATCH') {
                $group = array_key_exists('group_id', $body) ? $this->group($this->text($body, 'group_id', 32))['id'] : $device['group_id'];
                $name = array_key_exists('name', $body) ? $this->text($body, 'name') : $device['name'];
                $peer = array_key_exists('peer_id', $body) ? $this->peer($body) : $device['peer_id'];
                $platform = array_key_exists('platform', $body) ? $this->platform($body) : $device['platform'];
                $this->query('UPDATE devices SET group_id = ?, name = ?, peer_id = ?, platform = ? WHERE id = ?', [$group, $name, $peer, $platform, $id]);
                return ['device' => $this->device($id)];
            }
            if ($method === 'DELETE') {
                $this->query('UPDATE devices SET revoked_at = ?, token_hash = NULL WHERE id = ?', [time(), $id]);
                return ['ok' => true];
            }
        }
        if ($route === '/v1/invites' && $method === 'POST') {
            $group = $this->group($this->text($body, 'group_id', 32));
            $code = bin2hex(random_bytes(16));
            $expiry = time() + 86400;
            $this->query('DELETE FROM invites WHERE expires_at <= ? OR used_at IS NOT NULL', [time()]);
            $this->query('INSERT INTO invites(code_hash, group_id, expires_at) VALUES (?, ?, ?)', [hash('sha256', $code), $group['id'], $expiry]);
            return ['code' => $code, 'expires_at' => self::date($expiry)];
        }
        throw new ApiError(404, 'Operação não encontrada.');
    }
}
