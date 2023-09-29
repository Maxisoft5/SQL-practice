declare @User table(
	Id int,
	LName nvarchar(200),
	FName nvarchar(200),
	Tel nvarchar(15) null
);

declare @Territorys table(
	Id int,
	Name nvarchar(200),
	ParentID int null
);

declare @Network table(
	Id int,
	Name nvarchar(200)
);

declare @Shop table(
	Id int,
	Name nvarchar(200),
	CityId int,
	NetworkId int
);

declare @Plan table(
	Id int,
	UserId int,
	ShopId int,
	DT date,
	[PlanMin] int
);

declare @Fact table(
	Id int identity(1,1),
	PlanId int,
	FactFrom int,
	FactTo int
);


insert into @User(Id, LName, FName, Tel)
values (1, 'Иванов', 'Иван', '+7(123)1231212'), (2, 'Иванов', 'Вася', null);

insert into @Territorys(Id, Name, ParentID)
values (1, 'Moscow', null),
	   (2, 'Москва', 1),
	   (3, 'Владимир',   1),
	   (4, 'Center', null),
	   (5, 'Воронеж', 4),
	   (6, 'Орел', 4);

insert into @Network(Id, Name)
values (1, 'ABK'),
	   (2, 'Diksika'),
	   (3, 'Orion');

insert into @Shop(Id, Name, CityId ,NetworkId)
values (1, 'Shop1', 2, 1),
	   (2, 'Shop2', 2, 1),
	   (3, 'Shop3', 2, 1),
	   (4, 'Shop4', 2, 2),
	   (5, 'Shop5', 2, 2),
	   (6, 'Shop6', 3, 1),
	   (7, 'Shop7', 3, 2),
	   (8, 'Shop8', 5, 3),
	   (9, 'Shop9', 5, 3),
	   (10, 'Shop10', 5, 3),
	   (11, 'Shop11', 6, 3);


insert into @Plan(Id, UserId, ShopId, DT, [PlanMin])
values (1, 1, 1, '01.04.2016', 60),
 (2, 1, 1, '02.04.2016', 70),
 (3, 1, 1, '03.04.2016', 60),
 (4, 1, 2, '01.04.2016', 30),
 (5, 1, 2, '02.04.2016', 180),
 (6, 1, 3, '01.04.2016', 120),
 (7, 1, 4, '01.04.2016', 60),
 (8, 1, 4, '02.04.2016', 90),
 (9, 1, 5, '01.04.2016', 60),
 (10, 2, 6, '01.04.2016', 55),
 (11, 2, 6, '02.04.2016', 33),
 (12, 2, 6, '03.04.2016', 60),
 (13, 2, 7, '01.04.2016', 22),
 (14, 2, 7, '02.04.2016', 123),
 (15, 2, 8, '01.04.2016', 120),
 (16, 2, 9, '01.04.2016', 70),
 (17, 2, 10, '02.04.2016', 90),
 (18, 2, 11, '01.04.2016', 65);


 insert into @Fact(PlanId, FactFrom, FactTo)
values (1, 0, 23),
 (2, 500, 600),
 (3, 33, 44),
 (4, 666, 785),
 (6, 1300, 1500),
 (7, 401, 480),
 (8, 720, 875),
 (10, 234, 432),
 (11, 1, 11),
 (12, 11, 111),
 (13, 22, 222),
 (15, 33, 333),
 (16, 44, 444);


 --1. Необходимо написать запрос, результатом которого будет итоговые суммы плана и факта (формат hh:mm) по региону-городу-сети в формате xml.
--Решение должно быть в рамках одного запроса, без курсоров, временных таблиц и их аналогов.
--*Fact и Plan – это количество минут;
--**FactMin – это разница между FactTo и FactFrom.


 DECLARE @cityFilterON bit;
 DECLARE @regionFilterON bit;
 DECLARE @networkFilterON bit;
 SET @cityFilterON = 0;
 SET @networkFilterON = 0;
 SET @regionFilterON = 0;

 DECLARE @city NVARCHAR(50);
 SET @city = 'Воронеж';
 DECLARE @region NVARCHAR(50);
 SET @region = 'Moscow';
 DECLARE @networkFilter NVARCHAR(50);
 SET @networkFilter = 'ABK';

 DECLARE @searchXml XML;

SET @searchXml = (SELECT t.Name AS Region, IIF( (SELECT CAST( CAST((SUM(planRegions.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF((SUM(planRegions.PlanMin) - (CAST((SUM(planRegions.PlanMin) / 60) AS INT)) * 60) < 10, 
							      '0' + CAST((SUM(planRegions.PlanMin) - (CAST((SUM(planRegions.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
								  CAST((SUM(planRegions.PlanMin) - (CAST((SUM(planRegions.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
								 )
							FROM @Territorys terMinPlan 
							JOIN @Shop shopMinPlanRegion ON shopMinPlanRegion.CityId = terMinPlan.Id
							JOIN @Plan planRegions ON planRegions.ShopId = shopMinPlanRegion.Id
							WHERE terMinPlan.ParentID = t.Id ) IS NULL, 
							'0:00',  
								(SELECT CAST(CAST((SUM(planRegions.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
									IIF((SUM(planRegions.PlanMin) - (CAST((SUM(planRegions.PlanMin) / 60) AS INT)) * 60) < 10, 
									  '0' + CAST((SUM(planRegions.PlanMin) - (CAST((SUM(planRegions.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
										CAST((SUM(planRegions.PlanMin) - (CAST((SUM(planRegions.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
									)
									FROM @Territorys terMinPlan 
									JOIN @Shop shopMinPlanRegion ON shopMinPlanRegion.CityId = terMinPlan.Id
									JOIN @Plan planRegions ON planRegions.ShopId = shopMinPlanRegion.Id
									WHERE terMinPlan.ParentID = t.Id)) AS PlanMin,
						 IIF( (SELECT CAST(CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF( (SUM(factRegions.FactTo - factRegions.FactFrom) - (CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT)) * 60) < 10, 
								  '0' + CAST( (SUM(factRegions.FactTo - factRegions.FactFrom) - (CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
								  CAST( (SUM(factRegions.FactTo - factRegions.FactFrom) - (CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
								)
								FROM @Territorys terFactMinReg 
						    JOIN @Shop factMinRegShop ON factMinRegShop.CityId = terFactMinReg.Id
							JOIN @Plan planRegionsFact ON planRegionsFact.ShopId = factMinRegShop.Id
							LEFT JOIN @Fact factRegions ON factRegions.PlanId = planRegionsFact.Id
							WHERE terFactMinReg.ParentID = t.Id) IS NULL, '0:00' , (SELECT CAST(CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF( (SUM(factRegions.FactTo - factRegions.FactFrom) - (CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT)) * 60) < 10, 
								'0' + CAST( (SUM(factRegions.FactTo - factRegions.FactFrom) - (CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
								CAST( (SUM(factRegions.FactTo - factRegions.FactFrom) - (CAST((SUM(factRegions.FactTo - factRegions.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
								)
								FROM @Territorys terFactMinReg 
								JOIN @Shop factMinRegShop ON factMinRegShop.CityId = terFactMinReg.Id
								JOIN @Plan planRegionsFact ON planRegionsFact.ShopId = factMinRegShop.Id
								LEFT JOIN @Fact factRegions ON factRegions.PlanId = planRegionsFact.Id
								WHERE terFactMinReg.ParentID = t.Id) ) AS [FactMin],
	(SELECT terCity.Name AS City, 
	IIF( (SELECT CAST(CAST((SUM(planTer.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF((SUM(planTer.PlanMin) - (CAST((SUM(planTer.PlanMin) / 60) AS INT)) * 60) < 10, 
								'0' + CAST((SUM(planTer.PlanMin) - (CAST((SUM(planTer.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
								CAST((SUM(planTer.PlanMin) - (CAST((SUM(planTer.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
								FROM @Shop shopTer JOIN @Plan planTer on planTer.ShopId = shopTer.Id WHERE shopTer.CityId = terCity.Id) IS NULL,
								'0:00',
								(SELECT CAST(CAST((SUM(planTer.PlanMin) / 60) AS INT) as NVARCHAR(10)) + ':' + 
								IIF((SUM(planTer.PlanMin) - (CAST((SUM(planTer.PlanMin) / 60) AS INT)) * 60) < 10, 
								'0' + CAST((SUM(planTer.PlanMin) - (CAST((SUM(planTer.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
								CAST((SUM(planTer.PlanMin) - (CAST((SUM(planTer.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
								FROM @Shop shopTer JOIN @Plan planTer on planTer.ShopId = shopTer.Id WHERE shopTer.CityId = terCity.Id)) AS PlanMin,
	IIF( (SELECT 
		CAST(CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF( (SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) - (CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT)) * 60) < 10, 
								'0' + CAST( (SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) - (CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) , 
								CAST( (SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) - (CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
							)
	FROM @Shop shopFactMinCity JOIN @Plan planFactMinCity ON planFactMinCity.ShopId = shopFactMinCity.Id 
		JOIN @Fact factMinCityFact ON factMinCityFact.PlanId = planFactMinCity.Id WHERE shopFactMinCity.CityId = terCity.Id) IS NULL, '0:00', 
		 (SELECT 
		CAST(CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS int) AS NVARCHAR(10)) + ':' + 
								IIF( (SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) - (CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT)) * 60) < 10, 
								'0' + CAST( (SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) - (CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) , 
								CAST( (SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) - (CAST((SUM(factMinCityFact.FactTo - factMinCityFact.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
							)
	FROM @Shop shopFactMinCity JOIN @Plan planFactMinCity ON planFactMinCity.ShopId = shopFactMinCity.Id 
		JOIN @Fact factMinCityFact ON factMinCityFact.PlanId = planFactMinCity.Id WHERE shopFactMinCity.CityId = terCity.Id)) AS FactMin,
			(SELECT networkCity.Name AS Network,
			 IIF( (CAST(CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF((SUM(planCityNetwork.PlanMin) - (CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT)) * 60) < 10, 
								'0' + CAST((SUM(planCityNetwork.PlanMin) - (CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
								CAST((SUM(planCityNetwork.PlanMin) - (CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
								) is null,
								'0:00',
								(CAST(CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF((SUM(planCityNetwork.PlanMin) - (CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT)) * 60) < 10, 
								'0' + CAST((SUM(planCityNetwork.PlanMin) - (CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
								CAST((SUM(planCityNetwork.PlanMin) - (CAST((SUM(planCityNetwork.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
								)) AS PlanMin,
			 IIF( CAST(CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF( (SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) - (CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT)) * 60) < 10, 
								'0' + CAST( (SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) - (CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) , 
								CAST( (SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) - (CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
							) IS NULL, '0:00', 
		          CAST(CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
								IIF( (SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) - (CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT)) * 60) < 10, 
								'0' + CAST( (SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) - (CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) , 
								CAST( (SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) - (CAST((SUM(factCityNetwork.FactTo - factCityNetwork.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)))
		) AS FactMin
			FROM @Shop shopNet 
			JOIN @Network networkCity ON shopNet.NetworkId = networkCity.Id
			JOIN @Plan planCityNetwork ON planCityNetwork.ShopId = shopNet.Id
			LEFT JOIN @Fact factCityNetwork ON factCityNetwork.PlanId = planCityNetwork.Id
			WHERE shopNet.CityId = terCity.Id AND networkCity.Name = IIF(@networkFilterON = 1, @networkFilter, networkCity.Name)
			GROUP BY networkCity.Name
			FOR XML PATH('item'), ROOT('items'), TYPE)
	FROM @Territorys terCity WHERE terCity.ParentID = t.Id AND terCity.Name = IIF(@cityFilterON = 1, @city, terCity.Name) 
		FOR XML PATH('item'), ROOT('items'), TYPE)
FROM @Territorys t 
WHERE t.ParentID is null 
AND t.Id = IIF( @cityFilterON = 1, (SELECT TOP 1 ParentID FROM @Territorys WHERE Name =  @city), t.Id)
AND t.Name = IIF (@regionFilterON = 1, @region, t.Name)
AND EXISTS (SELECT TOP 1 * FROM @Territorys terFilterNetwork
	JOIN @Shop shopNetworkFilter on shopNetworkFilter.CityId = terFilterNetwork.Id
	JOIN @Network networkFilter on networkFilter.Id = shopNetworkFilter.NetworkId
	WHERE terFilterNetwork.ParentID = t.Id AND networkFilter.Name = IIF(@networkFilterON =1, @networkFilter, networkFilter.Name))
FOR XML PATH('item'), ROOT('items'), TYPE);

SELECT @searchXml as Result;
		
-- 2.Необходимо написать запрос, результатом которого будет сводная таблица, где столбцы это даты запланированных визитов, а строки план/факт сотрудников.
--Решение должно быть в рамках одного запроса, без курсоров и временных таблиц.
 

SELECT CONCAT(users.FName, ' ', users.LName) as Empl,
		(SELECT CONCAT(IIF( (CAST(CAST((SUM(plans.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) < 10, 
					'0' + CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
					CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
					) IS NULL,
					'0:00',
					(CAST(CAST((SUM(plans.PlanMin) / 60) AS INT) as NVARCHAR(10)) + ':' + 
					IIF((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) < 10, 
					'0' + CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
					CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
					)), ' / ', 
					IIF(SUM(facts.FactFrom-facts.FactTo) is null, '0:00', IIF( (CAST(CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) < 10, 
						'0' + CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
						CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
					)) IS NULL, '0:00' , 
					(CAST(CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) < 10, 
					'0' + CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
					CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
					) ) ))) FROM @Plan plans LEFT JOIN @Fact facts ON facts.PlanId=plans.Id WHERE plans.UserId = users.Id and plans.DT = '01.04.2016') as [01.04.2016],
		(SELECT CONCAT(IIF( (CAST(CAST((SUM(plans.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) < 10, 
					'0' + CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
					CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
					) IS NULL,
					'0:00',
					(CAST(CAST((SUM(plans.PlanMin) / 60) AS INT) as NVARCHAR(10)) + ':' + 
					IIF((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) < 10, 
					'0' + CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
					CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
					)), ' / ', 
		IIF(SUM(facts.FactFrom-facts.FactTo) is null, '0:00', IIF( (CAST(CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) < 10, 
						'0' + CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
						CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
					)) IS NULL, '0:00' , 
					(CAST(CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) < 10, 
					'0' + CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
					CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
					) ) ))) FROM @Plan plans LEFT JOIN @Fact facts ON facts.PlanId=plans.Id WHERE plans.UserId = users.Id and plans.DT = '02.04.2016') as [02.04.2016],
		(SELECT CONCAT(IIF( (CAST(CAST((SUM(plans.PlanMin) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) < 10, 
					'0' + CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
					CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
					) IS NULL,
					'0:00',
					(CAST(CAST((SUM(plans.PlanMin) / 60) AS INT) as NVARCHAR(10)) + ':' + 
					IIF((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) < 10, 
					'0' + CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)),
					CAST((SUM(plans.PlanMin) - (CAST((SUM(plans.PlanMin) / 60) AS INT)) * 60) AS NVARCHAR(10)))
					)), ' / ', 
		IIF(SUM(facts.FactFrom-facts.FactTo) is null, '0:00', IIF( (CAST(CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) < 10, 
						'0' + CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
						CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
					)) IS NULL, '0:00' , 
					(CAST(CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT) AS NVARCHAR(10)) + ':' + 
					IIF( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) < 10, 
					'0' + CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)), 
					CAST( (SUM(facts.FactTo - facts.FactFrom) - (CAST((SUM(facts.FactTo - facts.FactFrom) / 60) AS INT)) * 60) AS NVARCHAR(10)) 
					) ) ))) FROM @Plan plans LEFT JOIN @Fact facts ON facts.PlanId=plans.Id WHERE plans.UserId = users.Id and plans.DT = '03.04.2016') as [03.04.2016]
FROM @User users 
GROUP BY users.Id, users.FName, users.LName
ORDER BY Empl

-- 3. Необходимо написать запрос, результатом которого будет таблица с покупками всех клиентов,
--отсортированная в обратном хронологическом порядке. 
--В этой таблице должны отобразиться только те покупки, на которые хватит кредита. 
--Причем, в последней строке для каждого клиента должна быть указана не сумма покупки, а остаток кредита.
--Решение должно быть в рамках одного запроса, без курсоров и временных таблиц.


declare @UserCredit table (
	Id int IDENTITY(1,1),
	UserId int,
	Credit numeric(18,2)
);

insert into @UserCredit
  values (1, 20), (2, 25);
  
declare @UserPurchase table (
	Id int IDENTITY(1,1),
	UserId int,
	Cost numeric(18,2), 
	DT date, 
	Name varchar(50)
);

insert into @UserPurchase 
values
 (1, 5, '24.04.2016', 'sku1'),
 (1, 6, '19.04.2016', 'sku2'),
 (1, 7, '22.04.2016', 'sku3'),
 (1, 8, '04.04.2016', 'sku4'),
 (1, 4, '18.04.2016', 'sku5'),
 (1, 5, '18.04.2016', 'sku6'),
 (1, 2, '29.04.2016', 'sku7');
 insert into @UserPurchase 
values
 (2, 5, '24.04.2016', 'sku1'),
 (2, 6, '19.04.2016', 'sku2'),
 (2, 7, '22.04.2016', 'sku3'),
 (2, 8, '04.04.2016', 'sku4'),
 (2, 4, '18.04.2016', 'sku5'),
 (2, 2, '29.04.2016', 'sku7');

 SELECT userPurchases.Id, userPurchases.DT, userPurchases.Name, 
 Concat(userPurchases.Cost, ' / ', 
 (select top 1 Credit From @UserCredit WHERE UserId = users.Id) - ( (IIF((select sum(Cost) from @UserPurchase where UserId = users.Id and DT < userPurchases.DT) is null, 0, 
	    (select sum(Cost) from @UserPurchase where UserId = users.Id and DT < userPurchases.DT))
	+ (select sum(Cost) from @UserPurchase where UserId = users.Id 
	and (Id = userPurchases.Id or (DT = userPurchases.DT and Id > userPurchases.Id )) ) ))) as [Purchase Cost / Rest Credit]
	FROM @UserPurchase userPurchases
 JOIN @User users on users.Id = userPurchases.UserId
 JOIN @UserCredit credits on credits.UserId = users.Id
 group by userPurchases.Name, userPurchases.DT, users.Id, userPurchases.Cost, userPurchases.Id
 order by users.Id asc, userPurchases.DT desc



 




