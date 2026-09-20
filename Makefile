.PHONY: install ping prepare deploy vault-edit vault-view vault-encrypt

VAULT_FILE = group_vars/webservers/vault.yml

install:
	ansible-galaxy install -r requirements.yml

ping:
	ansible all -m ping

prepare:
	ansible-playbook playbook.yml --tags setup

deploy:
	ansible-playbook playbook.yml --tags deploy

vault-edit:
	ansible-vault edit $(VAULT_FILE)

vault-view:
	ansible-vault view $(VAULT_FILE)

vault-encrypt:
	ansible-vault encrypt $(VAULT_FILE)
