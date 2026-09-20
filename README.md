# Деплой Docker-образов с помощью Ansible

[![hexlet-check](https://github.com/Shawn4easy/devops-for-developers-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Shawn4easy/devops-for-developers-project-76/actions)

Автоматизация раскатывания контейнеризированного приложения на кластер машин в облаке.

**Приложение: https://shawn4easy.ru**

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-for-developers
Как это должно работать: https://asciinema.org/a/v4evn7XjCdou7Yh71IG0ljb0W

## Что развёрнуто

Redmine в Docker на двух виртуальных машинах за L7-балансировщиком. Обе машины
работают с общим кластером Managed PostgreSQL, поэтому запросы можно направлять
на любую из них. Трафик по HTTP перенаправляется на HTTPS, сертификат — Let's Encrypt.

Описание инфраструктуры и идентификаторы ресурсов — в [docs/infrastructure.md](docs/infrastructure.md).

## Стек

- Ansible — управление конфигурацией серверов и деплой
- Docker — запуск приложения в контейнерах
- Yandex Cloud — две виртуальные машины, L7-балансировщик, кластер PostgreSQL, Cloud DNS, Certificate Manager

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

### Секреты

Пароль базы данных и ключ подписи сессий Redmine хранятся в зашифрованном файле
`group_vars/webservers/vault.yml`. В репозиторий он не попадает — рядом лежит
образец `group_vars/webservers/vault.yml.example`.

Файл с паролем от vault создаётся один раз:

```bash
mkdir -p ~/.config/hexlet-devops-76
openssl rand -base64 32 > ~/.config/hexlet-devops-76/vault_pass
chmod 600 ~/.config/hexlet-devops-76/vault_pass
```

Путь к нему уже прописан в `ansible.cfg`. Дальше создаётся сам vault:

```bash
cp group_vars/webservers/vault.yml.example group_vars/webservers/vault.yml
make vault-encrypt
make vault-edit
```

Посмотреть содержимое, не расшифровывая файл на диске: `make vault-view`.

Заполнить нужно две переменные:

- `vault_redmine_db_password` — пароль пользователя `app` в кластере PostgreSQL
- `vault_redmine_secret_key_base` — ключ подписи сессий, `openssl rand -hex 64`

Ключ подписи обязан совпадать на обеих машинах: иначе сессия, выданная одним
сервером, не принимается вторым, и пользователя выбрасывает при переключении
бэкенда балансировщиком.

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

Развернуть приложение:

```bash
make deploy
```

`make deploy` запускает только приложение и не трогает настройки серверов:
подготовка и деплой разделены тегами Ansible (`setup` и `deploy`).

Обе команды идемпотентны — повторный запуск на настроенном окружении завершается
с `changed=0`.

## Настройки приложения

Переменные приложения лежат в `group_vars/webservers/vars.yml`, настройки
подготовки серверов — в `group_vars/all/main.yml`:

| Переменная | Значение | Назначение |
|---|---|---|
| `redmine_port` | `8080` | внешний порт контейнера |
| `redmine_image` | `redmine:6` | образ приложения |
| `redmine_dir` | `/opt/redmine` | каталог с `.env` на сервере |

Порт `8080` совпадает с портом в группе бэкендов балансировщика и с правилом в
группе безопасности `sg-app`. При его изменении нужно поправить и то, и другое.

Переменные окружения контейнера рендерятся из `templates/redmine.env.j2` в
`/opt/redmine/.env` и передаются в контейнер опцией `env_file`.

## Известные ограничения

**Вложения не общие.** Redmine хранит загруженные файлы на диске контейнера.
Сетевого тома между машинами нет, поэтому файл, загруженный через `app-01`, не
откроется, если следующий запрос уйдёт на `app-02`. Лечится общим хранилищем —
за рамками проекта.

**Docker Hub недоступен из Yandex Cloud.** `auth.docker.io` и `registry-1.docker.io`
не отвечают. В `daemon.json` прописано зеркало `https://mirror.gcr.io` —
pull-through кеш Google для Docker Hub. Настройка применяется ролью на шаге
`make prepare`, имена образов остаются обычными.

## Структура

```
.
├── ansible.cfg          конфигурация Ansible: инвентарь, пути к ролям, vault
├── inventory.ini        серверы, сгруппированные в webservers
├── requirements.yml     роли и коллекции Ansible Galaxy
├── playbook.yml         подготовка серверов (тег setup) и деплой (тег deploy)
├── group_vars/
│   ├── all/
│   │   └── main.yml            переменные подготовки серверов
│   └── webservers/
│       ├── vars.yml            переменные приложения
│       └── vault.yml.example   образец файла с секретами
├── templates/
│   └── redmine.env.j2   шаблон переменных окружения контейнера
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
