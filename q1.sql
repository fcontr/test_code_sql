
WITH abc AS (
  SELECT r.id AS retailer_id
  FROM tblRetailers r
  WHERE r.retailerName = 'ABC Store'
),

dedup AS (
  SELECT
      d.redemptionDate,
      ,d.redemptionCount
      ,d.createDateTime
      ROW_NUMBER() OVER (PARTITION by d.redemptionDateORDER by d.createDateTime desc, d.id desc) as rn
  FROM tblRedemptions_ByDay d
  JOIN  abc a ON a.retailer_id  = d.retailerId
   where d.redemptionDate BETWEEN DATE '2023-10-30' AND DATE '2023-11-05'
)
SELECT redemptionDate, redemptionCount
FROM dedup WHERE rn = 1
ORDER BY 1;
