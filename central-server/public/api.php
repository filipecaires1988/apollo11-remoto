<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/central.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header("Content-Security-Policy: default-src 'none'; frame-ancestors 'none'");
header('Referrer-Policy: no-referrer');

try {
    $configPath = getenv('APOLLO11_CENTRAL_CONFIG');
    if (!$configPath || !is_file($configPath)) {
        throw new RuntimeException('Configuration unavailable.');
    }
    $config = json_decode((string) file_get_contents($configPath), true, 8, JSON_THROW_ON_ERROR);
    if (!is_array($config) || !isset($config['database'], $config['password_hash'])) {
        throw new RuntimeException('Invalid configuration.');
    }
    $documentRoot = realpath($_SERVER['DOCUMENT_ROOT'] ?? '');
    foreach ([$configPath, $config['database']] as $privatePath) {
        $resolved = realpath($privatePath);
        if ($resolved === false || ($documentRoot !== false && ($resolved === $documentRoot || str_starts_with($resolved, $documentRoot . DIRECTORY_SEPARATOR)))) {
            throw new RuntimeException('Private storage must be outside the document root.');
        }
    }
    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || getenv('APOLLO11_TRUSTED_HTTPS') === '1';
    $ip = $_SERVER['REMOTE_ADDR'] ?? '';
    $localHttp = ($config['allow_loopback_http'] ?? false) === true && in_array($ip, ['127.0.0.1', '::1'], true);
    if (!$https && !$localHttp) {
        throw new ApiError(403, 'Esta central exige HTTPS.');
    }
    if ($https) {
        header('Strict-Transport-Security: max-age=31536000');
    }
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    $route = $_GET['route'] ?? '';
    if (!is_string($route) || strlen($route) > 160 || !preg_match('#^/v1/[a-z0-9/-]+$#D', $route)) {
        throw new ApiError(404, 'Operação não encontrada.');
    }
    $body = [];
    if (in_array($method, ['POST', 'PATCH', 'DELETE'], true)) {
        $raw = file_get_contents('php://input', false, null, 0, 16385);
        if ($raw === false || strlen($raw) > 16384) {
            throw new ApiError(413, 'Pedido muito grande.');
        }
        if ($raw !== '' || $method !== 'DELETE') {
            if (!str_starts_with(strtolower($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')) {
                throw new ApiError(415, 'Envie dados JSON.');
            }
            try {
                $decoded = json_decode($raw, false, 16, JSON_THROW_ON_ERROR);
            } catch (JsonException $error) {
                throw new ApiError(400, 'JSON inválido.');
            }
            if (!$decoded instanceof stdClass) {
                throw new ApiError(400, 'Envie um objeto JSON.');
            }
            $body = (array) $decoded;
        }
    }
    $authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    $token = preg_match('/^Bearer ([a-f0-9]{64})$/D', $authorization, $matches) ? $matches[1] : '';
    $result = (new CentralApi(central_database($config['database']), $config['password_hash'], $config['source_url'] ?? 'https://github.com/filipecaires1988/apollo11-remoto/tree/apollo11-central'))->dispatch($method, $route, $body, $token, $ip);
    echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
} catch (ApiError $error) {
    http_response_code($error->status);
    if ($error->status === 429) {
        header('Retry-After: 900');
    }
    echo json_encode(['error' => $error->getMessage()], JSON_UNESCAPED_UNICODE);
} catch (Throwable $error) {
    http_response_code(503);
    error_log('Apollo11 Central: server configuration or storage failure.');
    echo json_encode(['error' => 'A central está indisponível. Verifique a configuração do servidor.'], JSON_UNESCAPED_UNICODE);
}
