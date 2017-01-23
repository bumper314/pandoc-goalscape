#!/usr/bin/env php
<?php

require_once 'pandocfilters-php/pandocfilters.php';

Pandoc_Filter::toJSONFilter(function($type, $value, $format, $meta) use ($Header, $Str) {
	// Strip formatting from Headers (Goal names in Goalscape)
	if ('Header' == $type) {
		return $Header($value[0], $value[1], array($Str(Pandoc_Filter::stringify($value))));
	}
});

?>
