#!/bin/bash

perform_request '1.1.1.1' 1 '1.1.1.0|AU|13335|Cloudflare, Inc.'
perform_request '::ffff:1.1.1.1' 2 '1.1.1.0|AU|13335|Cloudflare, Inc.'
perform_request '192.168.0.1' 3 '192.168.0.0|00|00|00'
