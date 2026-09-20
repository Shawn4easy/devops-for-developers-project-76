# Деплой Docker-образов с помощью Ansible

[![hexlet-check](https://github.com/Shawn4easy/devops-for-developers-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Shawn4easy/devops-for-developers-project-76/actions)

Автоматизация раскатывания контейнеризированного приложения на кластер машин в облаке.

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-for-developers
Как это должно работать: https://asciinema.org/a/v4evn7XjCdou7Yh71IG0ljb0W

## Стек

- Ansible — управление конфигурацией серверов
- Docker — запуск приложения в контейнерах
- Yandex Cloud — две виртуальные машины, L7-балансировщик, кластер PostgreSQL

Описание инфраструктуры — в [docs/infrastructure.md](docs/infrastructure.md).

## Требования

На машине, с которой выполняется деплой:

- Ansible 2.15 или новее (`ansible --version`)
- `make`
- SSH-доступ к серверам

## Установка

```bash
git clone https://github.com/Shawn4easy/devops-for-developers-project-76.git
cd devops-for-developers-project-76
make install
```

`make install` скачивает роли и коллекции из Ansible Galaxy, перечисленные в
`requirements.yml`, в локальную директорию `.ansible/` — она не попадает в git.

### SSH-ключ

Серверы принимают подключения по ключу, путь к которому прописан в `inventory.ini`.
Если ключа ещё нет, он создаётся так:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/hexlet_devops_76 -C 'hexlet-devops-76'
```

Публичная часть должна быть добавлена пользователю `ubuntu` на обоих серверах.
При создании машин это делается через `cloud-init`, позже — через
`ssh-copy-id -i ~/.ssh/hexlet_devops_76.pub ubuntu@<адрес>`.

### Инвентарь

`inventory.ini` содержит группу `webservers` с двумя серверами:

```ini
[webservers]
app-01 ansible_host=51.250.69.112
app-02 ansible_host=84.201.152.93
```

Публичные адреса у машин динамические: после остановки и запуска они меняются.
Актуальные значения смотрятся командой `yc compute instance list`, после чего
правятся в `inventory.ini`.

## Использование

Проверить, что серверы доступны:

```bash
make ping
```

Подготовить серверы — установить pip, python-модуль `docker` и сам Docker:

```bash
make prepare
```

Команда идемпотентна: повторный запуск на настроенных серверах ничего не меняет
и завершается с `changed=0`.

## Структура

```
.
├── ansible.cfg          конфигурация Ansible: инвентарь, пути к ролям
├── inventory.ini        серверы, сгруппированные в webservers
├── requirements.yml     роли и коллекции Ansible Galaxy
├── playbook.yml         основной плейбук
├── group_vars/
│   └── all.yml          переменные ролей
├── Makefile             команды проекта
└── docs/
    └── infrastructure.md  описание инфраструктуры в облаке
```

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
