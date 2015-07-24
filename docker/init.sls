{% from "docker/map.jinja" import docker with context %}

docker-python-apt:
  pkg.installed:
    - name: python-apt

{% if "pkgrepo" in docker.kernel %}
{{ grains["oscodename"] }}-backports-repo:
  pkgrepo.managed:
    {% for key, value in docker.kernel.pkgrepo.items() %}
    - {{ key }}: {{ value }}
    {% endfor %}
    - require:
      - pkg: python-apt
    - onlyif: dpkg --compare-versions {{ grains["kernelrelease"] }} lt 3.8
{% endif %}

{% if "pkg"  in docker.kernel %}
docker-dependencies-kernel:
  pkg.installed:
    {% for key, value in docker.kernel.pkg.items() %}
    - {{ key }}: {{ value }}
    {% endfor %}
    - require_in:
      - pkg: lxc-docker
    - onlyif: dpkg --compare-versions {{ grains["kernelrelease"] }} lt 3.8
{% endif %}

docker-dependencies:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - iptables
      - ca-certificates
      - lxc

docker-repo:
  pkgrepo.managed:
    - humanname: Docker repo
    - name: deb https://get.docker.com/ubuntu docker main
    - file: /etc/apt/sources.list.d/docker.list
    - keyid: d8576a8ba88d21e9
    - keyserver: keyserver.ubuntu.com
    - refresh_db: True
    - require_in:
        - pkg: lxc-docker
    - require:
      - pkg: docker-python-apt

lxc-docker:
  {% if "version" in docker %}
  pkg.installed:
    - name: lxc-docker-{{ docker.version }}
  {% else %}
  pkg.latest:
  {% endif %}
    - refresh: {{ docker.refresh_repo }}
    - fromrepo: docker
    - require:
      - pkg: docker-dependencies

docker-config:
  file.managed:
    - name: /etc/default/docker
    - source: salt://docker/files/config
    - template: jinja
    - mode: 644
    - user: root

docker-service:
  service.running:
    - name: docker
    - enable: True
    - watch:
      - file: /etc/default/docker
    {% if "process_signature" in docker %}
    - sig: {{ docker.process_signature }}
    {% endif %}

docker-py requirements:
  pkg.installed:
    - name: python-pip
  pip.installed:
    {% if "pip_version" in docker %}
    - name: docker-py {{ docker.pip_version }}
    {% endif %}
    - require:
      - pkg: lxc-docker
    - reload_modules: True
