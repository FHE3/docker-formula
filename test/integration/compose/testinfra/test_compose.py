import pytest


def test_nginx_socket(host):
    socket = host.socket("tcp://:::80")
    assert socket.is_listening


def test_netbox_statuscode(host):
    headers = host.check_output("curl -I -X GET localhost")
    assert 'HTTP/1.1 200 OK' in headers


@pytest.mark.parametrize("volume, file", [
    ("netbox-netbox-data", "image-attachments"),
    ("netbox-nginx-config", "nginx.conf"),
    ("netbox-postgres-data", "PG_VERSION"),
    ("netbox-static-files", "admin"),
])
def test_volumes(host, file, volume):
    assert host.file("/var/lib/docker/volumes/" + volume + "/_data/" + file).exists
