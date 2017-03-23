#!/bin/bash

readonly color_red='echo -en \e[1;31m'
readonly color_blue='echo -en \e[1;34m'
readonly color_green='echo -en \e[1;32m'
readonly color_yellow='echo -en \e[1;33m'
readonly color_bwhielt='echo -en \e[1;37m'
readonly color_off='echo -en \e[0m'
#скрипт для фикса  данных по литологии/мадлогу на сервакак в соотвествии с эталонной таблицей.

source_file=$(find ~/ -name .bash_connection_info.sh 2>/dev/null | grep "bash_connection_info")
# while ! [ -f ${path_for_scr}/.bash_connection_info.sh ]; do
#     $color_bwhielt
#     echo -e "Необходимо подключить сурс-фаил 'bash_connection_info'."
#     echo -en "Введите путь до файла: " ; read path_for_scr
#     $color_off
# done
if [ -f $source_file ]; then
	. $source_file
else 
	echo "Фаил .bash_connection_info не найден!"
fi

if [ -z $1 ]
	then
	echo -e "\nВведите шорткат сервера\n"
	exit
fi

 mysql_quere="

set names utf8;

delimiter //
 

drop procedure if exists prepeare_base;
create procedure prepeare_base ()
begin

/* 1 часть. 
Чиста таблиц от лишних данных
*/
/*
	DELETE FROM WITS_LITHLOG_IDX WHERE id IN (SELECT idx_id FROM WITS_LITHLOG_DATA WHERE mnemonic LIKE 'CODELITH%' AND value>200);
	DELETE FROM WITS_MUDLOG_IDX WHERE id IN (SELECT idx_id FROM WITS_MUDLOG_DATA WHERE mnemonic LIKE 'CODELITH%' AND value>200);
	DELETE FROM WITS_LITHLOG_DATA WHERE idx_id IN (SELECT wd.idx_id WHERE WITS_LITHLOG_DATA wd LEFT OUTER JOIN WITS_LITHLOG_IDX wi ON (wi.id=wd.idx_id) WHERE wi.id IS NULL);
	DELETE FROM WITS_MUDLOG_DATA WHERE idx_id IN (SELECT wd.idx_id WHERE WITS_MUDLOG_DATA wd LEFT OUTER JOIN WITS_MUDLOG_IDX wi ON (wi.id=wd.idx_id) WHERE wi.id IS NULL);
*/
/* Создаём таблицу с комментами
Таблица с комментами
*/

	DROP TABLE IF EXISTS COMMENT_TABLE_FOR_LITH_TYPE_FIX;
	CREATE TEMPORARY TABLE COMMENT_TABLE_FOR_LITH_TYPE_FIX (
	  id bigint(20) NOT NULL,
	  comment varchar(255) NOT NULL DEFAULT 'unassigned',
	  KEY id (id)
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;

	INSERT INTO COMMENT_TABLE_FOR_LITH_TYPE_FIX VALUES (1, 'Таблица сопоставления литологических типов с текущего сервара -old  с эталлонной - new '),(2,'Сопоставление по id'),(3,'Сопоставление с имеющимися данными по геологии');


/* 2я часть 
Вставляем эталонную таблицу
*/

	DROP TABLE IF EXISTS WITS_MUDLOG_LITH_TYPE_NEW;
	CREATE TABLE WITS_MUDLOG_LITH_TYPE_NEW (
	  id bigint(20) NOT NULL,
	  name varchar(255) NOT NULL DEFAULT 'unassigned',
	  name_ru varchar(255) NOT NULL DEFAULT 'не классифицировано',
	  file_name varchar(255) DEFAULT NULL,
	  KEY id (id)
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;

	INSERT INTO WITS_MUDLOG_LITH_TYPE_NEW VALUES (1,'dispersed chert','рассеянный кремень',NULL),(2,'chert','кремень',NULL),(3,'silicified claystone','аргиллит',NULL),(4,'shale (clay)','глина',NULL),(5,'silty shale (silty clay)','алевритистая глина','4'),(6,'sandy shale','песчанистая глина','4'),(7,'marl','мергель',NULL),(8,'silty marl','алевритистый мергель',NULL),(9,'sandy marl','песчанистый мергель',NULL),(10,'silt','алеврит',NULL),(11,'fine grained sand','песок мелкозернистый',NULL),(12,'sand','песок',NULL),(13,'coarse grained sand','песок крупнозернистый',NULL),(14,'pebbles','галька',NULL),(15,'gravels','гравий',NULL),(16,'siltstone','алевролит',NULL),(17,'sandstone','песчаник',NULL),(18,'conglomerate','конгломерат',NULL),(19,'breccia','брекчия',NULL),(20,'limestone (argillaceous)','известняк глинистый',NULL),(21,'limestone (w chert nodule','известняк с кремниевыми конкрециями',NULL),(22,'limestone (silicified)','известняк кремнистый',NULL),(23,'limestone (dolomitic)','известняк доломитистый',NULL),(24,'limestone (chalk)','известняк мел',NULL),(25,'limestone (general)','известняк',NULL),(26,'mudstone','аргиллит известковистый',NULL),(27,'wackstone','мергель пелитоморфный',NULL),(28,'packstone','известняк обломочный',NULL),(29,'grainstone','известняк зернистый',NULL),(30,'boundstone','известняк строматолитовый',NULL),(31,'dolomite calcareous','доломит известковистый',NULL),(32,'dolomite','доломит',NULL),(33,'gypsum','гипс',NULL),(34,'Na, K, Mg salts','каменная соль',NULL),(35,'coal','уголь',NULL),(36,'extrusive rocks','вулканические породы',NULL),(37,'intrusive rocks','интрузивные породы',NULL),(38,'metamorphic rocks','метаморфические породы',NULL),(39,'volcanic elements','вулканогенный материал',NULL),(40,'unassigned','не классифицировано',NULL),(41,'sand (clay)','песок глинистый',NULL),(42,'chalk','мел',NULL),(43,'anhydrite','ангидрит',NULL),(44,'phosphates','фосфаты',NULL),(45,'peat','торф',NULL),(46,'crystalline basement','кристал. фундамент',NULL),(47,'quartzite','кварцит',NULL),(48,'bituminous clay','битуминозная глина','4'),(49,'bituminous mudstone','аргил. битум','3'),(50,'fine grained sandstone','песчаник мелкозернистый',NULL),(51,'gravelite','гравелит',NULL),(52,'sandy loam','сугленок супесь',NULL),(53,'interbedded sandstone and siltstone','переслаивание песчаника, аргилита и алевролита',NULL),(-1000,'no data','данные отсутствуют',NULL),(-2000,'incorrect data','ошибка ввода данных',NULL),(54,'anthracite','антрацит','7'),(55,'dolerite','долерит',NULL),(56,'dolomite argillaceous','доломит глинистый',NULL),(57,'clay calcareous ','глина известковистая','4');


 /* 3 часть.
 Сопоставляем NEW таблицу с имеющейся
 */ 

/*запихиваем все несоответствия во временную таблицу*/
	DROP TABLE IF exists LITH_TYPE_DIFF; 
	CREATE TEMPORARY TABLE LITH_TYPE_DIFF AS (SELECT old.id,old.name as 'OLD_name', old.name_ru as 'OLD_RU' , old.file_name,new.id as 'NEW_ID',new.name as 'NEW_name',new.name_ru as 'NEW_RU' FROM WITS_MUDLOG_LITH_TYPE old left outer join WITS_MUDLOG_LITH_TYPE_NEW new on (old.name=new.name) where  new.id is null order by old.id);
	select comment from COMMENT_TABLE_FOR_LITH_TYPE_FIX where id=1;
	select * from LITH_TYPE_DIFF;

/*снова сопоставляем с таблицей NEW для сравнения данных по айдишникам.*/
	DROP TABLE IF EXISTS LITH_TYPE_DIFF_CONCATED;
	CREATE TEMPORARY TABLE LITH_TYPE_DIFF_CONCATED AS (SELECT dif.*, new.id as id_new, new.name as name_new, new.name_ru as name_ru_new FROM LITH_TYPE_DIFF dif left outer join WITS_MUDLOG_LITH_TYPE_NEW new on (new.id=dif.id));
	

	select comment from COMMENT_TABLE_FOR_LITH_TYPE_FIX where id=2;
	SELECT * FROM LITH_TYPE_DIFF_CONCATED;

	/* вывод конката данных с типом, для определения какие пароды используются

	select wld.lith_in as LITH_IN, wmd.lith_in as MUD_IN, wmlt.*
	from WITS_MUDLOG_LITH_TYPE wmlt
	LEFT OUTER JOIN ( select value, COUNT(value) as lith_in from WITS_MUDLOG_DATA where mnemonic like 'CODELITH%' GROUP by value) as wmd ON (wmlt.id=wmd.value)
	LEFT OUTER JOIN ( select value, COUNT(value) as lith_in from WITS_LITHLOG_DATA where mnemonic like 'CODELITH%' GROUP by value) as wld ON (wmlt.id=wld.value)  order by wmlt.id ;

	*/


	/*подсчитываем все данные в списке 'отсутствующих'/требуемых переделки*/

	DROP TABLE IF EXISTS LITH_TYPE_DIFF_COUNTER;
	CREATE TEMPORARY TABLE LITH_TYPE_DIFF_COUNTER AS
	(select wld.lith_in AS LITH_DATA_COUNT, wmd.lith_in AS MUD_DATA_COUNT, wmlt.*
	from LITH_TYPE_DIFF_CONCATED wmlt
	LEFT OUTER JOIN ( select value, COUNT(value) as lith_in from WITS_MUDLOG_DATA where mnemonic like 'CODELITH%' GROUP by value) as wmd ON (wmlt.id=wmd.value)
	LEFT OUTER JOIN ( select value, COUNT(value) as lith_in from WITS_LITHLOG_DATA where mnemonic like 'CODELITH%' GROUP by value) as wld ON (wmlt.id=wld.value) where wld.lith_in>0 or wmd.lith_in>0 order by wmlt.id) ;
	/* выводим совпадения по породам.*/
	select comment from COMMENT_TABLE_FOR_LITH_TYPE_FIX where id=3;
	SELECT * FROM LITH_TYPE_DIFF_COUNTER;



end; 

drop procedure if exists clear;
create procedure clear()
begin
        SET @network := 15;

        DELETE FROM WITS_USER where network_id != @network;
        DELETE FROM WITS_USER_GROUP where network_id != @network;
        DELETE FROM WITS_USER_SETTINGS where user_id not in (select id from WITS_USER);
        DELETE FROM WITS_USER_COMMENTS where user_id not in (select id from WITS_USER);
        DELETE FROM comment where user_id not in (select id from WITS_USER);
        DELETE FROM chart_comments where user_id not in (select id from WITS_USER);

        DELETE FROM WITS_SOURCE where network_id != @network;
        DELETE FROM WITS_WELL_GROUP where network_id != @network;
        DELETE FROM WITS_WELL where source_id not in (select id from WITS_SOURCE);
        DELETE FROM WITS_WELL_PROP where well_id not in (select id from WITS_WELL);
        DELETE FROM WITS_WELLBORE where well_id not in (select id from WITS_WELL);

        DELETE FROM user_group_access where user_group_id not in (select id from WITS_USER_GROUP);
        DELETE FROM user_group_access where entity_type='well' and entity_id not in (select id from WITS_WELL);
        DELETE FROM user_group_access where entity_type='wellgroup' and entity_id not in (select id from WITS_WELL_GROUP);

        DELETE FROM record_offset where entity_type='source' and entity_id not in (select id from WITS_SOURCE);
        DELETE FROM record_offset where entity_type='well' and entity_id not in (select id from WITS_WELL);
        DELETE FROM record_offset where entity_type='wellbore' and entity_id not in (select id from WITS_WELLBORE);

        DELETE FROM opslog where well_id not in (select id from WITS_WELL);

        DELETE FROM rpt_list where well_id not in (select id from WITS_WELL);
        DELETE FROM rpt_data where report_id not in (select id from rpt_list);

        DELETE FROM WITS_SURVEY_IDX where wellbore_id not in (select id from WITS_WELLBORE);
        DELETE FROM WITS_SURVEY_DATA where idx_id not in (select id from WITS_SURVEY_IDX);

        DELETE FROM WITS_MUDLOG_IDX where wellbore_id not in (select id from WITS_WELLBORE);
        DELETE FROM WITS_MUDLOG_DATA where idx_id not in (select id from WITS_MUDLOG_IDX);
        DELETE FROM WITS_LITHLOG_IDX where wellbore_id not in (select id from WITS_WELLBORE);
        DELETE FROM WITS_LITHLOG_DATA where idx_id not in (select id from WITS_LITHLOG_IDX);
        DELETE FROM WITS_MUDLOG_IMAGE_IDX where wellbore_id not in (select id from WITS_WELLBORE);
        DELETE FROM WITS_MUDLOG_IMAGE where idx_id not in (select id from WITS_MUDLOG_IMAGE_IDX);
        DELETE FROM lba_image_idx where wellbore_id not in (select id from WITS_WELLBORE);
        DELETE FROM lba_image where idx_id not in (select id from lba_image_idx);
end;

DROP PROCEDURE if exists change_value_procedure_200;
	create procedure change_value_procedure_200()
	begin
		set @@sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

		 create TEMPORARY TABLE WITS_CHANGING_IDS as (select wld.lith_in as LITH_IN, wmd.lith_in as MUD_IN, wmlt.id as old_id ,wmltnew.id as new_id from WITS_MUDLOG_LITH_TYPE wmlt LEFT OUTER JOIN ( select value, COUNT(value) as lith_in from WITS_MUDLOG_DATA where mnemonic like 'CODELITH%' GROUP by value) as wmd ON (wmlt.id=wmd.value) LEFT OUTER JOIN ( select value, COUNT(value) as lith_in from WITS_LITHLOG_DATA where mnemonic like 'CODELITH%' GROUP by value) as wld ON (wmlt.id=wld.value) left outer join WITS_MUDLOG_LITH_TYPE_NEW wmltnew on (wmltnew.name=wmlt.name) where  wmlt.id>0 and wmltnew.id!=wmlt.id group by wmltnew.id order by wmlt.id); 
		 delete from WITS_CHANGING_IDS where LITH_IN is null and MUD_IN is null ;

		update WITS_MUDLOG_DATA ld inner join WITS_CHANGING_IDS wci on (wci.old_id=ld.value and mnemonic like 'CODELITH%' ) set ld.value=new_id;
		update WITS_LITHLOG_DATA ld inner join WITS_CHANGING_IDS wci on (wci.old_id=ld.value and mnemonic like 'CODELITH%' ) set ld.value=new_id;

	end;

DROP PROCEDURE if exists clear_the_way_for_new;
	create procedure clear_the_way_for_new ()
	begin

	DROP TABLE if exists WITS_MUDLOG_LITH_TYPE;
	RENAME TABLE WITS_MUDLOG_LITH_TYPE_NEW TO WITS_MUDLOG_LITH_TYPE;

	end;

//


delimiter ;


call prepeare_base;
call clear;
call change_value_procedure_200;
call clear_the_way_for_new;


/*
call delete_tables;
*/

drop procedure if exists change_value_procedure_200;
drop procedure if exists clear;
drop procedure if exists prepeare_base;
drop procedure if exists clear_the_way_for_new;
"

mysql_update_id_quere="
set names utf8;


delimiter //

UPDATE WITS_LITHLOG_IDX SET  well_id=well_id+168, wellbore_id=wellbore_id+201 , id=id+7537;
UPDATE WITS_MUDLOG_IDX SET  well_id=well_id+168, wellbore_id=wellbore_id+201 , id=id+72271 ;
UPDATE WITS_MUDLOG_IMAGE_IDX SET well_id=well_id+168, wellbore_id=wellbore_id+201 , id=id+10;
UPDATE lba_image_idx SET well_id=well_id+168, wellbore_id=wellbore_id+201;

UPDATE WITS_LITHLOG_DATA SET idx_id=idx_id+7537;

UPDATE WITS_MUDLOG_DATA SET idx_id=idx_id+72271;

UPDATE WITS_MUDLOG_IMAGE SET idx_id=idx_id+10;


//
"

mysql_connect=$(getServerInfo "mysql_not_safe" $1)
# изменение базы для бэкапа h5
mysql_connect=$(echo $mysql_connect | sed 's/WMLS/WMLS_h5/g')
mysql_dump=$(echo $mysql_connect | sed 's/mysql/mysqldump/g')
echo -en "\nВыбран сервер: " 
$color_green
 getServerInfo "project_name" $1
$color_off
echo -en "База: "
$color_blue
getServerInfo "base_name" $1
$color_off
#echo -e "Connect to \n" $mysql_connect

$color_yellow
echo -e "Подготавливаем таблицу... "
$color_off

$mysql_connect -A -e "$mysql_quere" 
$mysql_connect -A -e "$mysql_update_id_quere" 

$mysql_dump WITS_LITHLOG_IDX WITS_MUDLOG_IDX WITS_MUDLOG_IMAGE_IDX WITS_MUDLOG_IMAGE lba_image_idx lba_image WITS_MUDLOG_LITH_TYPE WITS_LITHLOG_DATA WITS_MUDLOG_DATA  > /tmp/H5.dump
if [ -f  /tmp/H5.dump ] ; then
	$color_green 
	echo "Создан дамп /tmp/H5.dump"
	 $color_off
else
	$color_red "Ошибка. Дамп не создан"
fi