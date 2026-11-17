<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
require_once __DIR__ . '/../src/central.php';

try {
    $directory = $argv[1] ?? '';
    $password = getenv('APOLLO11_ADMIN_PASSWORD');
    if ($directory === '' || $directory[0] !== DIRECTORY_SEPARATOR || !is_string($password) || strlen($password) < 12 || strlen($password) > 72 || str_contains($password, "\0")) {
        throw new RuntimeException('Use php bin/init.php /caminho/privado com APOLLO11_ADMIN_PASSWORD de 12 a 72 bytes no ambiente.');
    }
    $sourceUrl = getenv('APOLLO11_SOURCE_URL') ?: 'https://github.com/filipecaires1988/apollo11-remoto/tree/apollo11-central';
    $source = parse_url($sourceUrl);
    if (!filter_var($sourceUrl, FILTER_VALIDATE_URL) || !is_array($source) || ($source['scheme'] ?? '') !== 'https' || isset($source['user']) || isset($source['pass']) || isset($source['fragment'])) {
        throw new RuntimeException('APOLLO11_SOURCE_URL deve ser uma URL pública HTTPS dos fontes correspondentes, sem credenciais ou fragmento.');
    }
    umask(0077);
    if (!is_dir($directory) && !mkdir($directory, 0700, true)) {
        throw new RuntimeException('Não foi possível criar a pasta privada.');
    }
    $directory = realpath($directory);
    if ($directory === false || is_file($directory . '/config.json') || is_file($directory . '/central.sqlite')) {
        throw new RuntimeException('Use uma pasta privada nova para evitar sobrescrever uma central existente.');
    }
    $database = $directory . '/central.sqlite';
    central_schema(central_database($database));
    $config = ['database' => $database, 'password_hash' => password_hash($password, PASSWORD_DEFAULT), 'allow_loopback_http' => false, 'source_url' => $sourceUrl];
    if (file_put_contents($directory . '/config.json', json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR)) === false) {
        throw new RuntimeException('Não foi possível gravar a configuração.');
    }
    echo "Central criada. Configure APOLLO11_CENTRAL_CONFIG para o arquivo config.json desta pasta privada.\n";
} catch (Throwable $error) {
    fwrite(STDERR, $error->getMessage() . "\n");
    exit(1);
}
