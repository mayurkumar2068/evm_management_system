# MPSECIEMS — Schema Report
Generated: 2026-06-24T10:16:01.894Z
Total tables: 18

## Tables overview

| Table | Rows (approx) | Columns | PK | FKs |
| --- | --- | --- | --- | --- |
| BLOCKS | 10 | 6 | ID | 0 |
| Districts | 10 | 5 | ID | 0 |
| IEMS_SECSections | 1 | 4 | ID | 0 |
| IEMS_SECUsers | 1 | 6 | ID | 0 |
| JP | 0 | 7 | ID | 0 |
| JP_WARDS | 0 | 5 | ID | 0 |
| NNN | 3 | 8 | ID | 0 |
| NNN_TYPES | 3 | 4 | ID | 0 |
| PANCHAYATS | 10 | 11 | ID | 0 |
| PARTS | 4 | 11 | ID | 0 |
| RAUX_PS | 0 | 10 | ID | 0 |
| RPSBUILDINGS | 10 | 7 | ID | 0 |
| RWARDS | 10 | 10 | ID | 0 |
| STATES | 1 | 3 | ID | 0 |
| UPSBUILDINGS | 3 | 8 | ID | 0 |
| UWARDS | 5 | 8 | ID | 0 |
| ZP | 0 | 5 | ID | 0 |
| ZP_WARDS | 0 | 4 | ID | 0 |

## BLOCKS
Engine: InnoDB · Approx rows: 10

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| DIST_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| BLOCK_NAME | varchar(100) | Y |  |  |  |
| BLOCK_NAME_EN | varchar(100) | Y |  |  |  |

## Districts
Engine: InnoDB · Approx rows: 10

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| DIST_NO | int | N |  |  |  |
| DIST_NAME | varchar(50) | Y |  |  |  |
| DIST_NAME_EN | varchar(50) | Y |  |  |  |
| STATEID | varchar(30) | Y |  |  |  |

## IEMS_SECSections
Engine: InnoDB · Approx rows: 1

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | bigint | N | PRI | auto_increment |  |
| SectionName | varchar(500) | Y |  |  |  |
| isactive | tinyint(1) | Y |  |  |  |
| CreatedDate | datetime | Y |  |  |  |

## IEMS_SECUsers
Engine: InnoDB · Approx rows: 1

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | bigint | N | PRI | auto_increment |  |
| section | varchar(500) | Y |  |  |  |
| SO_Name | varchar(500) | Y |  |  |  |
| userid | varchar(500) | Y |  |  |  |
| password | varchar(500) | Y |  |  |  |
| isactive | tinyint(1) | Y |  |  |  |

## JP
Engine: InnoDB · Approx rows: 0

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| DIST_ID | varchar(50) | Y |  |  |  |
| BLOCK_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| JP_NAME | varchar(100) | Y |  |  |  |
| JP_NAME_EN | varchar(100) | Y |  |  |  |

## JP_WARDS
Engine: InnoDB · Approx rows: 0

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| JP_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| WARD_NO | int | N |  |  |  |

## NNN
Engine: InnoDB · Approx rows: 3

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| DIST_ID | varchar(50) | Y |  |  |  |
| NNN_TYPE_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| NNN_TYPE | varchar(3) | N |  |  |  |
| NNN_NO | int | N |  |  |  |
| NNN_NAME | varchar(100) | Y |  |  |  |
| NNN_NAME_EN | varchar(100) | Y |  |  |  |

## NNN_TYPES
Engine: InnoDB · Approx rows: 3

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| NNN_TYPE | varchar(3) | N |  |  |  |
| NNN_TYPE_DESC | varchar(100) | Y |  |  |  |
| NNN_TYPE_DESC_EN | varchar(100) | Y |  |  |  |

## PANCHAYATS
Engine: InnoDB · Approx rows: 10

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| BLOCK_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| PANCHYT_NO | int | N |  |  |  |
| PANCHYT_NAME | varchar(100) | Y |  |  |  |
| PANCHYT_NAME_EN | varchar(100) | Y |  |  |  |
| JPWARD_NO | int | Y |  |  |  |
| ZPWARD_NO | int | Y |  |  |  |
| JPWARD_ID | varchar(50) | Y |  |  |  |
| ZPWARD_ID | varchar(50) | Y |  |  |  |

## PARTS
Engine: InnoDB · Approx rows: 4

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| WARD_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| NNN_TYPE | varchar(3) | N |  |  |  |
| NNN_NO | int | N |  |  |  |
| WARD_NO | int | N |  |  |  |
| PART_NO | int | N |  |  |  |
| PART_NAME | varchar(100) | Y |  |  |  |
| PART_NAME_EN | varchar(100) | Y |  |  |  |
| UPSBUILDING_NO | int | Y |  |  |  |
| UPS_ID | varchar(50) | Y |  |  |  |

## RAUX_PS
Engine: InnoDB · Approx rows: 0

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| PANCHYT_ID | varchar(50) | Y |  |  |  |
| WARD_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| PANCHYT_NO | int | N |  |  |  |
| WARD_NO | int | N |  |  |  |
| AUX_NO | char(1) | N |  |  |  |
| RPS_ID | varchar(50) | Y |  |  |  |
| RPSBUILDING_NO | int | Y |  |  |  |

## RPSBUILDINGS
Engine: InnoDB · Approx rows: 10

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| BLOCK_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| RPSBUILDING_NO | int | N |  |  |  |
| RPSBUILDING_NAME | varchar(100) | Y |  |  |  |
| RPSBUILDING_NAME_EN | varchar(100) | Y |  |  |  |

## RWARDS
Engine: InnoDB · Approx rows: 10

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| PANCHYT_ID | varchar(50) | Y |  |  |  |
| VILL_ID | varchar(50) | Y |  |  |  |
| RPS_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| BLOCK_NO | int | N |  |  |  |
| PANCHYT_NO | int | N |  |  |  |
| WARD_NO | int | N |  |  |  |
| VILL_NO | int | N |  |  |  |
| RPSBUILDING_NO | int | Y |  |  |  |

## STATES
Engine: InnoDB · Approx rows: 1

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| STATE_CODE | varchar(10) | Y |  |  |  |
| STATE_NAME | varchar(100) | Y |  |  |  |

## UPSBUILDINGS
Engine: InnoDB · Approx rows: 3

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| NNN_ID | varchar(50) | N |  |  |  |
| DIST_NO | int | N |  |  |  |
| NNN_TYPE | varchar(3) | N |  |  |  |
| NNN_NO | int | N |  |  |  |
| UPSBUILDING_NO | int | N |  |  |  |
| UPSBUILDING_NAME | varchar(100) | Y |  |  |  |
| UPSBUILDING_NAME_EN | varchar(100) | Y |  |  |  |

## UWARDS
Engine: InnoDB · Approx rows: 5

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| NNN_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| NNN_TYPE | varchar(3) | N |  |  |  |
| NNN_NO | int | N |  |  |  |
| WARD_NO | int | N |  |  |  |
| WARD_NAME | varchar(256) | Y |  |  |  |
| WARD_NAME_EN | varchar(256) | Y |  |  |  |

## ZP
Engine: InnoDB · Approx rows: 0

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| DIST_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| ZP_NAME | varchar(50) | Y |  |  |  |
| ZP_NAME_EN | varchar(50) | Y |  |  |  |

## ZP_WARDS
Engine: InnoDB · Approx rows: 0

| Column | Type | Null | Key | Extra | Default |
| --- | --- | --- | --- | --- | --- |
| ID | varchar(50) | N | PRI |  |  |
| ZP_ID | varchar(50) | Y |  |  |  |
| DIST_NO | int | N |  |  |  |
| WARD_NO | int | N |  |  |  |
