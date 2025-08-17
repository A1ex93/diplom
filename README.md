## Дипломная работа по профессии «Системный администратор» - Гурылев А.В.

# Виртуальные машины

Скрипт, прилагаемый в документе по [код main.tf](https://github.com/A1ex93/diplom/blob/main/main.tf), успешно выполнил развёртывание инфраструктуры и создал 6 виртуальных машин в соответствии с поставленным заданием. Все ресурсы были развернуты в требуемом количестве и с соблюдением указанных параметров. Подтверждение выполнения — скриншоты развернутых виртуальных машин, представленные ниже. В целом все прошло хорошо, кроме сервера zabbix, которому в первом скрипте не выделил внешний адрес поэтому пришлось пересоздавать ВМ с помощью отдельного скрипта - [код zabbix.tf](https://github.com/A1ex93/diplom/blob/main/zabbix.tf)

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/all_vm.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/diski.png)

# Группы безопастности, подсети и тд

Так же прилагаемый скрипт terraform создал группы безопастности, сети, подсети, что так же отображено на скриншотах ниже

![Группы безопасности](https://github.com/A1ex93/diplom/blob/main/diplom_image/security-group.png)
![internal-ssh](https://github.com/A1ex93/diplom/blob/main/diplom_image/internal-ssh.png)
![elasticsearch-sg](https://github.com/A1ex93/diplom/blob/main/diplom_image/elasticsearch-sg.png)
![allow-web](https://github.com/A1ex93/diplom/blob/main/diplom_image/allow-web.png)
![kibana-sg](https://github.com/A1ex93/diplom/blob/main/diplom_image/kibana-sg.png)
![ru-central1](https://github.com/A1ex93/diplom/blob/main/diplom_image/ru-central1.png)
![Внутренняя сеть](https://github.com/A1ex93/diplom/blob/main/diplom_image/internal-zone.png)
![ru-central1](https://github.com/A1ex93/diplom/blob/main/diplom_image/ru-central1.png)

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

Протестировал работу балансировщика:

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/all_vm.png)

# Мониторинг
Публичный адрес zabbix - [http://62.84.112.9/zabbix/zabbix.php?action=dashboard.view&dashboardid=390&from=now-1h&to=now]

Установка сервера Zabbix прошла без возникновения каких-либо проблем. Была использована официальная документация для настройки Zabbix Server на базе операционной системы Ubuntu с применением СУБД PostgreSQL и веб-сервера Apache. Все компоненты успешно интегрировались, веб-интерфейс стал доступен по адресу, что подтвердило корректность развёртывания и настройки серверной части системы мониторинга.

Далее на все шесть виртуальных машин был установлен Zabbix Agent. На каждом хосте были выполнены необходимые настройки: указан адрес Zabbix Server, разрешён активный и пассивный режимы взаимодействия, агент добавлен в автозагрузку. После этого хосты были добавлены в веб-интерфейс Zabbix. В качестве основы для мониторинга использовался стандартный шаблон Template OS Linux by Zabbix agent, который предоставляет комплексный набор элементов (items) для сбора данных: загрузка CPU, использование памяти, состояние дискового пространства, сетевая активность и другие ключевые метрики. Привязка шаблона позволила быстро и единообразно настроить мониторинг всей инфраструктуры.
![Добавленные хосты](https://github.com/A1ex93/diplom/blob/main/diplom_image/zabbix-all.png)
![Созданный дашбоард](https://github.com/A1ex93/diplom/blob/main/diplom_image/zabbix-dashboard.png)

# Логи

Elasticsearch так же из-за санкций установить из официального репозитория не представляется возможным, поэтомму сделал в docker контейнере используя команду -  

sudo docker run -d   --name elasticsearch2   -p 9200:9200   -p 9300:9300   -e "discovery.type=single-node"   -e "ES_JAVA_OPTS=-Xms256m -Xmx256m"   -e "xpack.security.enabled=false"   -v /opt/elasticsearch//usr/share/elasticsearch/data   -v /opt/elasticsearch/logs:/usr/share/elasticsearch/logs   --restart unless-stopped sebp/elk

C kibana возникла аналогичная проблема, которые решил такм же образом.

![Доступность kibana](https://github.com/A1ex93/diplom/blob/main/diplom_image/elasticsearch-curl.png)

![Elasticsearch security group](https://github.com/A1ex93/diplom/blob/main/diplom_image/elasticsearch-sg.png)

![Веб интерфейс kibana](https://github.com/A1ex93/diplom/blob/main/diplom_image/kibana-elastic-web.png)

Развертывание стека Elasticsearch и Kibana прошло успешно, взаимодействие между компонентами настроено корректно. Elasticsearch принимает данные от Filebeat, индексирует их и хранит в соответствующих индексах, что подтверждается наличием актуальных записей при проверке через API. Filebeat, установленный на всех целевых виртуальных машинах, стабильно собирает логи и передаёт их в Elasticsearch без задержек и ошибок. В Kibana данные отображаются в режиме реального времени — созданы индекс-паттерны, на основе которых настроены поиск и визуализация событий. Доступ к веб-интерфейсу Kibana обеспечен, что позволяет эффективно анализировать логи, отслеживать аномалии и оперативно реагировать на инциденты. Таким образом, лог-сбор и централизованное хранение логов функционируют в штатном режиме.

Публичный адрес kibana - [http://84.201.156.147:5601/]

# Резервное копирование
Создал расписание выполнения snapshot дисков всех ВМ, настроил согласно заданию ежедневное выполнение и время жизни snapshot 7 дней.

![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/snapshot.png)
![alt text](https://github.com/A1ex93/diplom/blob/main/diplom_image/shapshot-schedule.png)
