# api_sat_puppet_param Ansible Role

This Ansible role creates, updates or deletes a Puppet parameter override for a host on a Satellite server.

## Requirements

* The Satellite API authentication on mtl-sat02p.cn.ca **DOES NOT** use IDM. It uses your internal account password (like `hammer`). As such, make sure you go into your account settings and set/update your password. This is the password you'll need for this role to work.
* Or course, you also need "Edit" access on the target host.

## Role Variables

The following variables are defined in `defaults/main.yml`:

```yaml
# MANDATORY: User and password to use to authenticate to the Satellite API (default is to use the Ansible user/pw)
sat_api_user: "{{ ansible_user }}"
sat_api_password: "{{ ansible_password }}"

# MANDATORY: Satellite server URL (i.e. http(s)://hostname.domain.tld)
sat_url: https://mtl-sat02p.cn.ca

# MANDATORY: FQDN of host on which to set/update/delete parameter (e.g. mtl-ptcdev01d.cn.ca)
# host:

# MANDATORY: Puppet class name (e.g. cn_nscd)
# puppetclass_name:

# MANDATORY: Namr of parameter (e.g. service_running)
# parameter_name:

# MANDATORY: Value of parameter (e.g. stopped)
# parameter_value:

# If true, parameter is created or updated to override Puppet defaults, if false, parameter is deleted
override: yes

# If set to no, Satellite SSL certificate will not be validated
validate_certs: yes
```

## Dependencies

This role has no dependencies.

## Example Playbook

```yaml
- hosts: localhost
  tasks:
    - include_role:
        name: api_sat_puppet_param
      vars:
        validate_certs: no
        host: mtl-ptcdev01d.cn.ca
        puppetclass_name: cn_nscd
        parameter_name: service_running
        parameter_value: stopped
        override: yes
```

## Limitations

* When enumerating `override_values` using the API, the page size is set to 1000 items and paging logic has not been implemented. As such, if using this role to *update/delete* an existing parameter for a parameter that has more than 1000 overrides, the one for your server may not be found. This does not affect creation of a new parameter *BUT* may fail the playbook if run more than once in that situation (because the POST API call will fail since the parameter already exist).

## Author Information

Marco Ponton (marco.ponton@cn.ca)
