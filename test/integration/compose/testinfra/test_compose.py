import time
import pytest
import json

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

@pytest.mark.parametrize("container, policy, process", [
    ("netbox", "", ""),
    ("nginx", "always", "nginx"),
    ("postgres", "", ""),
])
def test_restartpolicy(host, container, policy, process):
    with host.sudo():
        docker_inspect = json.loads(host.check_output("docker inspect " + container))
        assert docker_inspect[0]['HostConfig']['RestartPolicy']['Name'] == policy
        if policy in ('always', ):
            process_to_kill = host.process.get(user="root", comm=process)
            host.run('kill %s' % process_to_kill.pid)
            for i in range(0,10):
                try:
                    new_process = host.process.get(user="root", comm=process)
                    break
                except:
                    time.sleep(1)
            assert new_process.pid != process_to_kill.pid
            docker_inspect_restart = json.loads(host.check_output("docker inspect " + container))
            assert docker_inspect_restart[0]['RestartCount'] == docker_inspect[0]['RestartCount'] + 1
