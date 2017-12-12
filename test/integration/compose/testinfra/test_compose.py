def test_nginx_socket(host):
    socket = host.socket("tcp://:::80")
    assert socket.is_listening


def test_netbox_statuscode(host):
    headers = host.check_output("curl -I -X GET localhost")
    assert 'HTTP/1.1 200 OK' in headers


#def test_netbox_