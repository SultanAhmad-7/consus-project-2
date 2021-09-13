SELECT 
	names.names_id,
	(SELECT prefix.name FROM prefix WHERE prefix.id=names.prefixid) AS prefix,
	names.first_name AS first_name,
	names.last_long_name AS last_name,
	(SELECT suffix.name FROM suffix WHERE suffix.id=names.suffixid) AS suffix,
	(SELECT TOP 1 provider_role_list.role	 FROM provider,provider_roles,provider_role_list WHERE names.id=provider.id AND provider.id=provider_roles.providerid AND   provider_roles.providerrolelistid=provider_role_list.id) AS provider_role,
	(SELECT TOP 1 names.names_id FROM provider WHERE names.id=provider.id ) AS provider_id,
	(SELECT TOP 1 party_role_list.role FROM party,party_role_list WHERE party.namesid=names.id AND party_role_list.id=party.partyrolelistid) AS party_role,
	(SELECT TOP 1 names.names_id FROM party WHERE party.namesid=names.id ) AS party_id,
	names.person AS person,
	(SELECT multi_addresses.company FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS company,
	(SELECT multi_addresses.county FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS county,
	(SELECT multi_addresses.address FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS address1,
	(SELECT multi_addresses.address_2 FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS address_2,
	(SELECT multi_addresses.city FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS city1,
	(SELECT multi_addresses.state FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS state1,
	(SELECT multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS zipcode1,
	names.date_of_birth,
	(SELECT  '(' + SUBSTRING(number,1,3) + ') ' 
           + SUBSTRING(number,4,3) + '-' 
           + SUBSTRING(number,7,4) FROM phone WHERE namesid = names.id AND title = 'Home') AS Home_Phone,
	(SELECT  '(' + SUBSTRING(number,1,3) + ') ' 
           + SUBSTRING(number,4,3) + '-' 
           + SUBSTRING(number,7,4) FROM phone WHERE namesid = names.id AND title = 'Business') AS Business_Phone,
	(SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id AND online_account_category.id = online_accounts.onlineaccountcategoryid
			and online_account_category.title = 'Email' AND online_accounts.type = 0) AS Home_Email,
	names.date_created,
	names.date_modified,
	(SELECT staff.staff_code FROM staff WHERE names.staffcreatedid=staff.id) AS staff_created
FROM 
	names
WHERE
	  (SELECT TOP 1 provider_role_list.role FROM provider,provider_roles,provider_role_list WHERE names.id=provider.id AND provider.id=provider_roles.providerid 
		AND  provider_roles.providerrolelistid=provider_role_list.id) in  ('Intake')


 
	
