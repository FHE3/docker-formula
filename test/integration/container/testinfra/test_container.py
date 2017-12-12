def test_service_is_running_and_enabled(host):
    docker = host.service('docker-helloworld')
    assert docker.is_running
    assert docker.is_enabled


def test_helloworld_socket(host):
    socket = host.socket("tcp://:::5000")
    assert socket.is_listening


def test_running_container(host):
    with host.sudo():
        container = host.check_output("sudo docker ps --format {{.Image}}")
    assert container == "dockercloud/hello-world"


def test_docker_output(host):
    with host.sudo():
        output = host.check_output("sudo docker run hello-world")
        assert "Hello from Docker!" in output
