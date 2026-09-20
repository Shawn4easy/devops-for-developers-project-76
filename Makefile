.PHONY: install ping prepare

install:
	ansible-galaxy install -r requirements.yml

ping:
	ansible all -m ping

prepare:
	ansible-playbook playbook.yml
