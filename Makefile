.PHONY: install ping prepare deploy

install:
	ansible-galaxy install -r requirements.yml

ping:
	ansible all -m ping

prepare:
	ansible-playbook playbook.yml --tags setup

deploy:
	ansible-playbook playbook.yml --tags deploy
