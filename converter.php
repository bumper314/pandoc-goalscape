<?php
error_reporting(E_ALL);

$pandoc   = realpath("../../.local/bin/") . "/pandoc";
$writer   = realpath(".") . "/pandoc-goalscape/goalscape.lua";
$template = realpath(".") . "/pandoc-goalscape/default.goalscape";
$filter   = realpath(".") . "/pandoc-goalscape/pandoc-filter-goalscape.php";

// Limiting import formats
$formats = array(
	'commonmark' => 'CommonMark',
	'docbook' => 'DocBook',
	//'docx' => 'Docx (Word)',
	//'epub' => 'ePub',
	'haddock' => 'Haddock Markup',
	'html' => 'HTML',
	//'json' => 'JSON (Pandoc AST)',
	'latex' => 'LateX',
	'markdown' => 'Markdown (Pandoc)',
	'markdown_strict' => 'Markdown (Strict)',
	'markdown_github' => 'Markdown (GitHub)',
	'markdown_mmd' => 'Markdown (MultiMarkdown)',
	'markdown_phpextra' => 'Markdown (PHP Extra)',
	'mediawiki' => 'MediaWiki',
	//'odt' => 'ODT',
	'opml' => 'OPML',
	'org' => 'OrgMode (Emacs)',
	'rst' => 'reStructuredText',
	'textile' => 'Textile',
	't2t' => 'Txt2Tags',
	'twiki' => 'TWiki'
);

function formatOptions() {
	$opts = "";
	global $formats;
	foreach ($formats as $value => $pretty) {
		$selected = ($value == 'markdown')?" selected":"";
		$opts .= <<<EOO
						<option value="$value"$selected>$pretty</option>
EOO;
	}
	return $opts;
}

// Convert and download or fallthrough the web form
$source = '';
$error = '';
if(isset($_REQUEST['format']) && isset($_REQUEST['convert_text']) && isset($_REQUEST['source'])) {
	$format = $_REQUEST['format'];
	if(!array_key_exists($format, $formats)) {
		$error = "Unknown source format: $format";
		goto fallthrough;
	}
	$source = mb_convert_encoding($_REQUEST['source'], "UTF-8");
	// TODO: Limit size
	if(empty($source)) {
		$error = "Source text can not be empty";
		goto fallthrough;
	}
	
	$descriptors = array(
		0 => array("pipe", "r"),  // stdin
		1 => array("pipe", "w"),  // stdout
		2 => array("pipe", "w"),  // stderr
	);
	$cmd = "$pandoc --from $format --to $writer --template $template --filter $filter";
	$process = proc_open($cmd, $descriptors, $pipes, "/", null);
	
	fwrite($pipes[0], $source);
	fclose($pipes[0]);
	
	$stdout = stream_get_contents($pipes[1]);
	fclose($pipes[1]);
	
	$stderr = stream_get_contents($pipes[2]);
	fclose($pipes[2]);
	
	if(empty($stdout)) {
		$error = "Failed to convert: $stderr";
		goto fallthrough;
	} else { // Download result
		header('Content-Type: application/download');
		header('Content-Disposition: attachment; filename="Converted.gsp"');
		header("Content-Length: " . strlen($stdout));
		print $stdout;
		return; // NO FALLTHROUGH
	}
}
fallthrough:
?>
<html>
<head>
	<title>Convert to Goalscape</title>
	<link rel="stylesheet" href="style.css" type="text/css" media="screen" />
</head>
<body>
	<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post" name="gs" class="form-style-1">
		<fieldset>
			<legend>Convert to Goalscape</legend>
			<ul>
				<?php echo empty($error)?"":"<li class='error'>" . htmlentities($error) . "</li>"; ?>
				<li><label>Format:</label>
					<select name="format" class="field-select">
						<?php echo formatOptions() ?>
					</select>
				</li>
				<li><label>Source:<textarea name="source" class="field-long field-textarea"><?php echo htmlentities($source) ?></textarea></label></li>
				<li class="field-buttons">
					<input type="submit" name="convert_text" value="Download Goalscape Project" />
				</li>
			</ul>	
		</fieldset>
	</form>
	<div style="text-align: center">
		<a href="https://github.com/bumper314/pandoc-goalscape/tree/dingus#example-usage" target="_blank">Example Usage</a>
	</div>
</body>
</html>
