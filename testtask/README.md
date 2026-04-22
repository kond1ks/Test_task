# KPI Drive Kanban (Flutter Web)

Kanban доска в стиле Trello/KPI-DRIVE с загрузкой задач из KPI Drive API и сохранением изменений (`parent_id`, `order`).

## Запуск (Web)

1. Установите зависимости proxy:

```bash
cd proxy
npm install
```

2. Запустите proxy (для обхода CORS браузера):

```bash
npm start
```

3. В другом терминале запустите Flutter web:

```bash
flutter run -d edge
```

По умолчанию Flutter web ходит в proxy: `http://localhost:8787`.

## Переопределение URL proxy

Можно задать другой URL через `--dart-define`:

```bash
flutter run -d edge --dart-define=WEB_PROXY_BASE_URL=http://localhost:8787
```
