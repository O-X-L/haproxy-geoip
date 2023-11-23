package cnf

const DB_TYPE_MAXMIND uint8 = 2

// MaxMind schema: https://github.com/maxmind/MaxMind-DB/tree/main/source-data
var MAXMIND_COUNTRY struct {
	Country struct {
		Code         string `maxminddb:"iso_code"`
		Id           uint   `maxminddb:"geoname_id"`
		EuopeanUnion bool   `maxminddb:"is_in_european_union"`
	} `maxminddb:"country"`
	RegisteredCountry struct {
		Code         string `maxminddb:"iso_code"`
		Id           uint   `maxminddb:"geoname_id"`
		EuopeanUnion bool   `maxminddb:"is_in_european_union"`
	} `maxminddb:"registered_country"`
	Continent struct {
		Code  string            `maxminddb:"code"`
		Id    uint              `maxminddb:"geoname_id"`
		Names map[string]string `maxminddb:"names"`
	} `maxminddb:"continent"`
}

var MAXMIND_ASN struct {
	ASN  string `maxminddb:"autonomous_system_number"`
	Name string `maxminddb:"autonomous_system_organization"`
}

var MAXMIND_CITY struct {
	City struct {
		Code string `maxminddb:"iso_code"`
		Id   uint   `maxminddb:"geoname_id"`
	} `maxminddb:"country"`
	Country struct {
		Code         string `maxminddb:"iso_code"`
		Id           uint   `maxminddb:"geoname_id"`
		EuopeanUnion bool   `maxminddb:"is_in_european_union"`
	} `maxminddb:"country"`
	RegisteredCountry struct {
		Code         string `maxminddb:"iso_code"`
		Id           uint   `maxminddb:"geoname_id"`
		EuopeanUnion bool   `maxminddb:"is_in_european_union"`
	} `maxminddb:"registered_country"`
	Continent struct {
		Code  string            `maxminddb:"code"`
		Id    uint              `maxminddb:"geoname_id"`
		Names map[string]string `maxminddb:"names"`
	} `maxminddb:"continent"`
	Location struct {
		AccuracyRadius uint    `maxminddb:"accuracy_radius"`
		Latitude       float32 `maxminddb:"latitude"`
		Longitude      float32 `maxminddb:"longitude"`
		Timezone       string  `maxminddb:"time_zone"`
	} `maxminddb:"location"`
	Postal struct {
		Code string `maxminddb:"code"`
	} `maxminddb:"postal"`
	Traits struct {
		IsAnycast        bool `maxminddb:"is_anycast"`
		IsAnonymousProxy bool `maxminddb:"is_anonymous_proxy"`
	} `maxminddb:"traits"`
}

var MAXMIND_PRIVACY struct { // also called 'anonymous'
	Any          bool `maxminddb:"is_anonymous"`
	Vpn          bool `maxminddb:"is_anonymous_vpn"`
	Tor          bool `maxminddb:"is_tor_exit_node"`
	Hosting      bool `maxminddb:"is_hosting_provider"`
	PublicProxy  bool `maxminddb:"is_public_proxy"`
	PrivateProxy bool `maxminddb:"is_residential_proxy"`
}
