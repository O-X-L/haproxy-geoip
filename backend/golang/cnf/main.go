package cnf

const PORT = 7069

var LOOKUP_MAPPING = map[uint8]interface{}{
	DB_TYPE_IPINFO: map[string]interface{}{
		"country_asn": IPINFO_COUNTRY_ASN,
		"country":     IPINFO_COUNTRY,
		"city":        IPINFO_CITY,
		"asn":         IPINFO_ASN,
		"privacy":     IPINFO_PRIVACY,
	},
	DB_TYPE_MAXMIND: map[string]interface{}{
		"country_asn": nil,
		"country":     MAXMIND_COUNTRY,
		"city":        MAXMIND_CITY,
		"asn":         MAXMIND_ASN,
		"privacy":     MAXMIND_PRIVACY,
	},
}

var LOOKUP = LOOKUP_MAPPING[DB_TYPE].(map[string]interface{})
