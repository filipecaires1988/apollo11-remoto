#!/usr/bin/env python3
"""Integration checks against a real PHP HTTP server and an isolated SQLite file."""

import concurrent.futures
import json
import os
from pathlib import Path
import shlex
import socket
import sqlite3
import subprocess
import tempfile
import time
import unittest
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


SERVER = Path(__file__).resolve().parents[1]
PHP = shlex.split(os.environ.get("PHP_BINARY", "php"))


class CentralIntegration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="apollo11-central-test-")
        cls.private = Path(cls.temp.name) / "private"
        cls.password = "Synthetic-Only-Password-2026"
        environment = os.environ | {"APOLLO11_ADMIN_PASSWORD": cls.password}
        subprocess.run(PHP + [str(SERVER / "bin/init.php"), str(cls.private)], env=environment, check=True, capture_output=True)
        cls.config_path = cls.private / "config.json"
        config = json.loads(cls.config_path.read_text())
        config["allow_loopback_http"] = True
        cls.config_path.write_text(json.dumps(config))
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        cls.url = f"http://127.0.0.1:{port}/api.php"
        cls.log = open(Path(cls.temp.name) / "server.log", "wb")
        cls.process = subprocess.Popen(
            PHP + ["-S", f"127.0.0.1:{port}", "-t", str(SERVER / "public")],
            env=os.environ | {"APOLLO11_CENTRAL_CONFIG": str(cls.config_path), "PHP_CLI_SERVER_WORKERS": "4"},
            stdout=cls.log, stderr=cls.log, start_new_session=True,
        )
        for _ in range(100):
            try:
                cls.request("GET", "/v1/source", expected=200)
                break
            except OSError:
                if cls.process.poll() is not None:
                    raise RuntimeError("PHP server terminated during startup.")
                time.sleep(0.03)
        else:
            raise RuntimeError("PHP server startup timed out.")

    @classmethod
    def tearDownClass(cls):
        import signal
        os.killpg(cls.process.pid, signal.SIGTERM)
        cls.process.wait(timeout=5)
        cls.log.close()
        cls.temp.cleanup()

    @classmethod
    def request(cls, method, route, body=None, token=None, expected=200, raw=None, content_type="application/json"):
        headers = {}
        if token:
            headers["Authorization"] = "Bearer " + token
        data = raw if raw is not None else None if body is None else json.dumps(body).encode()
        if data is not None:
            headers["Content-Type"] = content_type
        request = Request(cls.url + "?" + urlencode({"route": route}), data=data, method=method, headers=headers)
        try:
            response = urlopen(request, timeout=10)
        except HTTPError as error:
            response = error
        with response:
            result = json.loads(response.read())
            if response.status != expected:
                raise AssertionError(f"{method} {route}: expected {expected}, got {response.status}: {result}")
            if response.headers.get("Cache-Control") != "no-store":
                raise AssertionError("API responses must disable caching.")
            return result

    def login(self):
        return self.request("POST", "/v1/admin/login", {"password": self.password})["token"]

    def test_01_auth_and_http_validation(self):
        self.request("GET", "/v1/groups", expected=401)
        self.request("POST", "/v1/admin/login", {"password": "wrong-password"}, expected=401)
        self.request("POST", "/v1/admin/login", raw=b"{", expected=400)
        self.request("POST", "/v1/admin/login", raw=b"[]", expected=400)
        self.request("POST", "/v1/admin/login", raw=b"{}", content_type="text/plain", expected=415)
        self.request("POST", "/v1/admin/login", raw=b"x" * 16385, expected=413)
        self.request("POST", "/v1/admin/login", {"password": "x" * 73}, expected=401)
        self.assertEqual(self.request("GET", "/v1/source")["license"], "AGPL-3.0")

    def test_02_catalog_enrollment_permissions_and_revocation(self):
        token = self.login()
        group = self.request("POST", "/v1/groups", {"name": "Cliente de teste"}, token)["group"]
        other = self.request("POST", "/v1/groups", {"name": "Outro cliente de teste"}, token)["group"]
        self.request("POST", "/v1/groups", {"name": "Cliente de teste"}, token, expected=409)
        self.assertEqual(len(self.request("GET", "/v1/groups", token=token)["groups"]), 2)
        device = self.request("POST", "/v1/devices", {"group_id": group["id"], "name": "Recepção de teste", "peer_id": "123456789", "platform": "Windows"}, token)["device"]
        self.assertIsNone(device["last_seen"])
        self.request("POST", "/v1/devices", {"group_id": group["id"], "name": "ID inválido", "peer_id": "123;malformed", "platform": "Windows"}, token, expected=422)
        self.request("POST", "/v1/devices", {"group_id": group["id"], "name": "Sistema inválido", "peer_id": "123456789", "platform": "Mac OS"}, token, expected=422)
        self.request("DELETE", "/v1/groups/" + group["id"], token=token, expected=409)
        invitation = self.request("POST", "/v1/invites", {"group_id": group["id"]}, token)
        enrollment = {"code": invitation["code"], "name": "Mac de teste", "peer_id": "987654321", "platform": "macOS"}
        enrolled = self.request("POST", "/v1/enroll", enrollment)
        self.assertEqual(enrolled["group_name"], group["name"])
        self.request("POST", "/v1/enroll", enrollment, expected=401)
        agent = enrolled["device_token"]
        self.request("GET", "/v1/devices", token=agent, expected=401)
        self.request("PATCH", "/v1/devices/" + device["id"], {"name": "Unauthorized"}, agent, expected=401)
        self.request("POST", "/v1/heartbeat", {"peer_id": "987654321", "platform": "macOS", "group_id": other["id"], "name": "Ignored"}, agent)
        catalog = self.request("GET", "/v1/devices", token=token)["devices"]
        registered = next(item for item in catalog if item["id"] == enrolled["device_id"])
        self.assertEqual(registered["group_id"], group["id"])
        self.assertEqual(registered["name"], "Mac de teste")
        self.assertTrue(registered["last_seen"].endswith("Z"))
        self.request("PATCH", "/v1/devices/" + registered["id"], {"name": "Apelido do técnico", "group_id": other["id"]}, token)
        self.request("POST", "/v1/heartbeat", {"peer_id": "987654322", "platform": "macOS"}, agent)
        catalog = self.request("GET", "/v1/devices", token=token)["devices"]
        registered = next(item for item in catalog if item["id"] == enrolled["device_id"])
        self.assertEqual(registered["name"], "Apelido do técnico")
        self.assertEqual(registered["group_id"], other["id"])
        self.assertEqual(registered["peer_id"], "987654322")
        self.request("DELETE", "/v1/devices/" + registered["id"], token=token)
        self.request("POST", "/v1/heartbeat", {"peer_id": "987654322"}, agent, expected=401)
        self.request("DELETE", "/v1/groups/" + other["id"], token=token)
        self.request("DELETE", "/v1/devices/" + device["id"], token=token)
        self.request("PATCH", "/v1/groups/" + group["id"], {"name": "Cliente renomeado"}, token)
        self.request("DELETE", "/v1/groups/" + group["id"], token=token)
        self.request("POST", "/v1/admin/logout", {}, token)
        self.request("GET", "/v1/groups", token=token, expected=401)

    def test_03_invite_failure_rolls_back_and_concurrent_use_is_single(self):
        token = self.login()
        group = self.request("POST", "/v1/groups", {"name": "Concorrência de teste"}, token)["group"]
        self.request("POST", "/v1/devices", {"group_id": group["id"], "name": "Existente", "peer_id": "333333333", "platform": "Windows"}, token)
        invitation = self.request("POST", "/v1/invites", {"group_id": group["id"]}, token)
        body = {"code": invitation["code"], "name": "Novo", "peer_id": "333333333", "platform": "Windows"}
        self.request("POST", "/v1/enroll", body, expected=409)
        body["peer_id"] = "444444444"
        self.request("POST", "/v1/enroll", body)
        invitation = self.request("POST", "/v1/invites", {"group_id": group["id"]}, token)
        def enroll(peer):
            request = Request(self.url + "?" + urlencode({"route": "/v1/enroll"}), data=json.dumps({"code": invitation["code"], "name": "Concorrente", "peer_id": peer, "platform": "Windows"}).encode(), headers={"Content-Type": "application/json"})
            try:
                response = urlopen(request, timeout=10)
            except HTTPError as error:
                response = error
            with response:
                response.read()
                return response.status
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            results = list(executor.map(enroll, ["555555555", "666666666"]))
        self.assertEqual(sorted(results), [200, 401])
        with sqlite3.connect(self.private / "central.sqlite") as db:
            self.assertEqual(db.execute("SELECT COUNT(*) FROM devices WHERE group_id=?", (group["id"],)).fetchone()[0], 3)
            self.assertEqual(db.execute("SELECT COUNT(*) FROM devices WHERE token_hash=?", (invitation["code"],)).fetchone()[0], 0)

    def test_04_https_source_expiry_and_limits(self):
        token = self.login()
        with sqlite3.connect(self.private / "central.sqlite") as db:
            db.execute("UPDATE admin_sessions SET expires_at=0")
        self.request("GET", "/v1/groups", token=token, expected=401)
        config = json.loads(self.config_path.read_text())
        config["allow_loopback_http"] = False
        self.config_path.write_text(json.dumps(config))
        self.request("GET", "/v1/source", expected=403)
        config["allow_loopback_http"] = True
        self.config_path.write_text(json.dumps(config))
        private_database = config["database"]
        config["database"] = str(SERVER / "public" / "api.php")
        self.config_path.write_text(json.dumps(config))
        self.request("GET", "/v1/source", expected=503)
        config["database"] = private_database
        self.config_path.write_text(json.dumps(config))
        token = self.login()
        group = self.request("POST", "/v1/groups", {"name": "Convite vencido"}, token)["group"]
        invitation = self.request("POST", "/v1/invites", {"group_id": group["id"]}, token)
        with sqlite3.connect(self.private / "central.sqlite") as db:
            db.execute("UPDATE invites SET expires_at=0")
        self.request("POST", "/v1/enroll", {"code": invitation["code"], "name": "Vencido", "peer_id": "777777777", "platform": "Windows"}, expected=401)
        with sqlite3.connect(self.private / "central.sqlite") as db:
            db.execute("DELETE FROM invites")
            db.execute("DELETE FROM devices")
            db.execute("DELETE FROM groups")
            db.executemany("INSERT INTO groups(id,name) VALUES (?,?)", [(f"{number:032x}", f"Limit{number}") for number in range(500)])
        self.request("POST", "/v1/groups", {"name": "Excesso"}, token, expected=409)
        with sqlite3.connect(self.private / "central.sqlite") as db:
            db.executemany("INSERT INTO devices(id,group_id,name,peer_id,platform) VALUES (?,?,?,?,?)", [(f"{number+1000:032x}", "0" * 32, f"Limit{number}", str(100000000+number), "Windows") for number in range(5000)])
        self.request("POST", "/v1/devices", {"group_id": "0" * 32, "name": "Excesso", "peer_id": "999999999", "platform": "Windows"}, token, expected=409)

    def test_05_login_rate_limit(self):
        with sqlite3.connect(self.private / "central.sqlite") as db:
            db.execute("DELETE FROM rate_limits")
        for _ in range(10):
            self.request("POST", "/v1/admin/login", {"password": "wrong-password"}, expected=401)
        self.request("POST", "/v1/admin/login", {"password": self.password}, expected=429)


if __name__ == "__main__":
    unittest.main(verbosity=2)
