package lookup

import (
	"net"

	"github.com/superstes/haproxy-geoip/backend/golang/cnf"
)

func MaxMindCountry(ip net.IP, dataStructure interface{}) interface{} {
	return lookupBase(ip, dataStructure, cnf.DB_COUNTRY)
}

func MaxMindCity(ip net.IP, dataStructure interface{}) interface{} {
	return lookupBase(ip, dataStructure, cnf.DB_CITY)
}

func MaxMindAsn(ip net.IP, dataStructure interface{}) interface{} {
	return lookupBase(ip, dataStructure, cnf.DB_ASN)
}

func MaxMindPrivacy(ip net.IP, dataStructure interface{}) interface{} {
	return lookupBase(ip, dataStructure, cnf.DB_PRIVACY)
}
