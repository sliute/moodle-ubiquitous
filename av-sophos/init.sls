av-sophos.deps:
  pkg.latest:
    - name: build-essential

{% if not salt['file.directory_exists'](pillar['av-sophos']['install_dir']) %}
av-sophos.install:
  cmd.run:
    - name: |
        rm -rf {{ pillar['av-sophos']['tmp_dir'] }}

        if [ ! -f {{ pillar['av-sophos']['tmp_file'] }} ]; then
            wget -O {{ pillar['av-sophos']['tmp_file'] }} {{ pillar['av-sophos']['url'] }}
        fi

        mkdir -p {{ pillar['av-sophos']['tmp_dir'] }}
        tar -xz -f {{ pillar['av-sophos']['tmp_file'] }} -C {{ pillar['av-sophos']['tmp_dir'] }}
        {{ pillar['av-sophos']['tmp_dir'] }}/sophos-av/install.sh \
                --automatic --acceptlicense --ignore-existing-installation \
                {% for option, value in salt['pillar.get']('av-sophos:install_options', {}).items() %}--{{ option }}={{ value }} {% endfor %} \
                {{ pillar['av-sophos']['install_dir'] }}

        rm -f {{ pillar['av-sophos']['tmp_file'] }}
        rm -rf {{ pillar['av-sophos']['tmp_dir'] }}
{% endif %}

{% for option, value in pillar['av-sophos']['savconfig_options'].items() %}
av-sophos.savconfig.{{ option }}:
  cmd.run:
    - name: /opt/sophos-av/bin/savconfig set {{ option | yaml }} {{ value | yaml }}
    - unless: /opt/sophos-av/bin/savconfig get {{ option | yaml }} | grep {{ value | yaml }}
{% endfor %}

av-sophos.savupdate:
  cmd.run:
    - name: /opt/sophos-av/bin/savupdate --verbose=5
