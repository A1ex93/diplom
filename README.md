## Дипломная работа по профессии «Системный администратор» - Гурылев А.В.

# Инфраструктура

# Сайт

Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

# Балансировщик

Target Group

Backend Group

HTTP router.

Application load balancer

Публичный адрес балансировщика - [http://84.252.132.76/]

Протестируйте сайт curl -v <публичный IP балансера>:80

Мониторинг
Публичный адрес zabbix - [http://62.84.112.9/zabbix/zabbix.php?action=dashboard.view&dashboardid=390&from=now-1h&to=now]

Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix.

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть.

Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Публичный адрес kibana - [http://89.169.150.38:5601/app/home#/]

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

sudo docker run -d   --name elasticsearch2   -p 9200:9200   -p 9300:9300   -e "discovery.type=single-node"   -e "ES_JAVA_OPTS=-Xms256m -Xmx256m"   -e "xpack.security.enabled=false"   -v /opt/elasticsearch//usr/share/elasticsearch/data   -v /opt/elasticsearch/logs:/usr/share/elasticsearch/logs   --restart unless-stopped sebp/elk

Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте Security Groups соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Эта вм будет реализовывать концепцию bastion host . Синоним "bastion host" - "Jump host". Подключение ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью ProxyCommand . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через NAT-шлюз.

Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.
