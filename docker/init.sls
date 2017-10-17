{% from "docker/map.jinja" import docker with context %}
{% if docker.kernel is defined %}
include:
  - .kernel
{% endif %}

docker package dependencies:
  pkg.installed:
    - pkgs:
      {%- if grains['os_family']|lower == 'debian' %}
      - apt-transport-https
      - python-apt
      {%- endif %}
      - iptables
      - ca-certificates

{%- if grains['os_family']|lower == 'debian' %}
docker package repository:
  pkgrepo.managed:
    - name: deb {{ docker.repo_name }} {{ grains["oscodename"]|lower }} {{ docker.repo_component }}
    - humanname: {{ grains["os"] }} {{ grains["oscodename"]|capitalize }} Docker Package Repository
    - key_url: {{ docker.repo_keyurl }}
    - file: {{ docker.repo_file }}
    - refresh_db: True
{%- elif grains['os_family']|lower == 'redhat' and (grains['os']|lower != 'amazon' and grains['os']|lower != 'fedora') %}
docker package repository:
  pkgrepo.managed:
    - name: docker
    - baseurl: https://yum.dockerproject.org/repo/main/centos/$releasever/
    - gpgcheck: 1
    - gpgkey: https://yum.dockerproject.org/gpg
    - require_in:
      - pkg: docker package
    - require:
      - pkg: docker package dependencies
{%- endif %}

docker package:
  {%- if "version" in docker %}
  pkg.installed:
    - name: docker-ce
    - version: {{ docker.version }}
    - hold: True
  {%- else %}
  pkg.latest:
    - name: docker-ce
  {%- endif %}
    - refresh: {{ docker.refresh_repo }}
    - require:
      - pkg: docker package dependencies
      - pkgrepo: docker package repository
      - file: docker-config
      {% if grains["init"] == 'systemd' %}
      - file: docker-systemd-service-conf
      {% endif %}


{% if grains["init"] == 'systemd' %}
docker-systemd-service-conf:
  file.managed:
    - name: /etc/systemd/system/docker.service
    - source: salt://docker/files/service.conf

service.systemctl_reload:
  module.run:
    - onchanges:
      - file: docker-systemd-service-conf

docker-config-directory:
  file.directory:
    - name: /etc/docker

docker-config:
  file.managed:
    - name: /etc/docker/daemon.json
    - source: salt://docker/files/daemon.json
    - template: jinja
    - mode: 644
    - user: root
    - require:
      - file: docker-config-directory
{% else %}
docker-config:
  file.managed:
    - name: /etc/default/docker
    - source: salt://docker/files/config
    - template: jinja
    - mode: 644
    - user: root
{% endif %}

docker-service:
  service.running:
    - name: docker
    - enable: True
    - watch:
{% if grains["init"] == 'systemd' %}
      - file: /etc/docker/daemon.json
{% else %}
      - file: /etc/default/docker
{% endif %}
      - pkg: docker package
    {% if "process_signature" in docker %}
    - sig: {{ docker.process_signature }}
    {% endif %}


{% if docker.install_docker_py %}
docker-py requirements:
  pkg.installed:
    - name: {{ docker.python_pip_package }}
  pip.installed:
    {%- if "pip" in docker and "version" in docker.pip %}
    - name: pip {{ docker.pip.version }}
    {%- else %}
    - name: pip
    - upgrade: True
    {%- endif %}

docker-py:
  pip.installed:
    {%- if "python_package" in docker %}
    - name: {{ docker.python_package }}
    {%- elif "pip_version" in docker %}
    - name: docker-py {{ docker.pip_version }}
    {%- else %}
    - name: docker-py
    {%- endif %}
    - reload_modules: true
{% endif %}
