## Дипломная работа по профессии «Системный администратор» - Гурылев А.В.

# Виртуальные машины

Скрипт, прилагаемый в документе по [код main.tf](https://github.com/A1ex93/diplom/blob/main/main.tf), успешно выполнил развёртывание инфраструктуры и создал 6 виртуальных машин в соответствии с поставленным заданием. Все ресурсы были развернуты в требуемом количестве и с соблюдением указанных параметров. Подтверждение выполнения — скриншоты развернутых виртуальных машин, представленные ниже. В целом все прошло хорошо, кроме сервера zabbix, которому в первом скрипте не выделил внешний адрес поэтому пришлось пересоздавать ВМ с помощью отдельного скрипта - [код zabbix.tf](https://github.com/A1ex93/diplom/blob/main/zabbix.tf)

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/all_vm.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/diski.png)

# Группы безопастности, подсети и тд

Так же прилагаемый скрипт terraform создал группы безопастности, сети, подсети, что так же отображено на скриншотах ниже

[Группы безопасности](https://github.com/A1ex93/diplom/blob/main/diplom_image/security-group.png)
[Внутренняя сеть](https://github.com/A1ex93/diplom/blob/main/diplom_image/internal-zone.png)
[Подсети](https://github.com/A1ex93/diplom/blob/main/diplom_image/security-group.png)
[ru-central1](https://github.com/A1ex93/diplom/blob/main/diplom_image/ru-central1.png)

# Софт

С установкой софта возникли проблемы в виду санкций часть софта пришлось скачивать через VPN и загружать на ВМ через scp, часть поднял в докере,

Nginx на первом веб-сервере
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/nginx-web-1.png)
Nginx на втором веб-сервере
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/nginx-web-2.png)
Filebeat на первом веб-сервере
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/filebeat-web-1.png)
Filebeat на втором веб-сервере
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/filebeat-web-2.png)
Установка zabbix на сервере мониторинга
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/zabbix-install.png)
Установка кибана в докере
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/kibana-with-docker.png)
Установка elasticsearch также выполнил докере
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/elasticsearch-with-docker.png)

# Балансировщик

Далее с помощью yc cli мною был настроен балансировщик, для управления трафиком поступающим на веб-серверы

Target Group

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/target-group.png)

Backend Group

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/backend-group.png)

HTTP router.

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/route-table.png)

Application load balancer

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/balancer.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/balancer1.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/balancer2.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/balancer3.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/balancer4.png)

Публичный адрес балансировщика - [http://84.252.132.76/]

Протестируйте сайт curl -v <публичный IP балансера>:80

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/all_vm.png)

# Мониторинг
Публичный адрес zabbix - [http://62.84.112.9/zabbix/zabbix.php?action=dashboard.view&dashboardid=390&from=now-1h&to=now]

Установка сервера Zabbix прошла без возникновения каких-либо проблем. Была использована официальная документация для настройки Zabbix Server на базе операционной системы Ubuntu с применением СУБД PostgreSQL и веб-сервера Apache. Все компоненты успешно интегрировались, веб-интерфейс стал доступен по адресу, что подтвердило корректность развёртывания и настройки серверной части системы мониторинга.

Далее на все шесть виртуальных машин был установлен Zabbix Agent. На каждом хосте были выполнены необходимые настройки: указан адрес Zabbix Server, разрешён активный и пассивный режимы взаимодействия, агент добавлен в автозагрузку. После этого хосты были добавлены в веб-интерфейс Zabbix. В качестве основы для мониторинга использовался стандартный шаблон Template OS Linux by Zabbix agent, который предоставляет комплексный набор элементов (items) для сбора данных: загрузка CPU, использование памяти, состояние дискового пространства, сетевая активность и другие ключевые метрики. Привязка шаблона позволила быстро и единообразно настроить мониторинг всей инфраструктуры.

![Добавленные хосты](https://github.com/A1ex93/diplom/blob/main/diplom_image/zabbix-all.png)

# Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Публичный адрес kibana - [http://89.169.150.38:5601/app/home#/]

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

sudo docker run -d   --name elasticsearch2   -p 9200:9200   -p 9300:9300   -e "discovery.type=single-node"   -e "ES_JAVA_OPTS=-Xms256m -Xmx256m"   -e "xpack.security.enabled=false"   -v /opt/elasticsearch//usr/share/elasticsearch/data   -v /opt/elasticsearch/logs:/usr/share/elasticsearch/logs   --restart unless-stopped sebp/elk

# Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте Security Groups соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Эта вм будет реализовывать концепцию bastion host . Синоним "bastion host" - "Jump host". Подключение ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью ProxyCommand . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)



# Резервное копирование
Создал расписание выполнения snapshot дисков всех ВМ, настроил согласно заданию ежедневное выполнение и время жизни snapshot 7 дней.

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/snapshot.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/shapshot-schedule.png)
