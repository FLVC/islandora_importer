<?php

/**
 * @file
 * Importer interface for the heavy-lifting.
 */

interface IslandoraBatchImporterInterface {
  /**
   * Determine if we're ready to run our batch process...
   *
   * ... probably checking values.  Might almost be thought of as validation?
   *
   * @param array $form_state
   *   An array containing the form state.
   *
   * @return bool
   *   A boolean indicating whether or not we have all the info to start the
   *   batch is available.
   */
  public static function readyForBatch(array &$form_state);

  /**
   * Get the info for the source parameter for the itemClass factory.
   *
   * This is also used to populate the file parameter to the Importer's
   * constructor.
   *
   * @param array $form_state
   *   An array containing the form state (very likely resulting from the
   *   submission of the form returned from self::getForm
   *
   * @return mixed
   *   Whatever (serializable) data will be passed to self::$itemClass->getOne()
   */
  public static function getBatchInfo(array &$form_state);
}

/**
 * Batch importer interface/abstract class.
 *
 * Implement the abstract functions (and those in the Import Object/item class)
 * and it should be able to work.
 *
 * @author adam@discoverygarden.ca
 */
abstract class IslandoraBatchImporter extends IslandoraBatchPreprocessor implements IslandoraBatchImporterInterface {
  /**
   * A string containing the name of the class to actually do the heavy
   * lifting.
   * @var string
   */
  protected $itemClass = "IslandoraImportObject";

  /**
   * May be a  bit of a misnomer...  We don't really make any assumptions
   *   about what this holds...  We just pass it as a parameter to
   *   abstract methods...  Irrespective of whether the given implementation
   *   actually uses them.  Probably has to be serializable to work properly
   *   with the batch stuff.
   * @var mixed
   */
  protected $file;

  /**
   * The Fedora collection PID into which items should be imported as members.
   * @var string
   */
  protected $parentPid;

  /**
   * Store the batch context, to avoid passing it to individual methods.
   * @var array
   */
  protected $context;

  /**
   * Constructor.
   *
   * Just store the passed in parameters in members.
   *
   * @param IslandoraTuque $connection
   *   A Tuque connection, so we can setup objects.
   * @param mixed $file
   *   May be a  bit of a misnomer...  We don't really make any assumptions
   *   about what this holds...  We just pass it along to the item class.
   * @param string $parent_pid
   *   The PID if the parent to which the ingested objects will belong.
   */
  public function __construct(IslandoraTuque $connection, $file, $parent_pid) {
    $this->file = $file;
    $this->parentPid = $parent_pid;

    $parameters = array(
      'file' => $file,
      'parent_pid' => $parent_pid,
    );

    parent::__construct($connection, $parameters);
  }

  /**
   * Get the form for this importer.
   *
   * Could have a multiple-page form given readyForBatch and the form state.
   */
  public static function getForm(array &$form_state) {
    return array(
      'nothing' => array(
        '#type' => 'item',
        '#value' => t('Warning: this importer does not define a form'),
      ),
    );
  }

  /**
   * Get the number of items to import from $this->file.
   *
   * @return int
   *   The number of items left to process.
   */
  public abstract function getNumber();

  /**
   * Get an identifier.
   *
   * @return string
   *   An identifier for the repo.
   */
  protected function getIdentifier(IslandoraTuque $tuque, $namespace) {
    if (empty($this->context['results']['pid_cache'])) {
      // Get enough PIDs for half of the remaining items.
      // (plus one, so we'll always get at least one).
      $this->context['results']['pid_cache'] = (array) $tuque->api->m->getNextPid(
        $namespace,
        intval((($this->context['sandbox']['max'] - $this->context['sandbox']['progress']) / 2) + 1)
      );
    }

    return array_shift($this->context['results']['pid_cache']);
  }

  /**
   * Try to get the namespace from the collection policy.
   *
   * @param IslandoraImportObject $item
   *   So we can get the item's namepace, if we don't get one from a collection
   *   policy.
   *
   * @return string
   *   The namespace with which the object should be ingested.
   */
  protected function getNamespace($item) {
    // Get namespace based on collection, then from item.
    $collection_policies =& drupal_static(__METHOD__, array());
    $namespace = $item->pidNamespace;
    if (module_exists('islandora_basic_collection') && !isset($collection_policies[$this->parentPid])) {
      $parent = islandora_object_load($this->parentPid);
      if (isset($parent['COLLECTION_POLICY'])) {
        $policy_stream = $parent['COLLECTION_POLICY'];
        $collection_policies[$this->parentPid] = new CollectionPolicy($policy_stream->content);
      }
    }
    if (isset($collection_policies[$this->parentPid])) {
      $info = $collection_policies[$this->parentPid]->getContentModels();
      $applicable = array_intersect_key($info, drupal_map_assoc($item->getContentModels()));
      if ($applicable) {
        $first_applicable = reset($applicable);
        $namespace = $first_applicable['namespace'];
      }
    }

    return $namespace;
  }

  /**
   * Inherited.
   */
  public function preprocess() {
    $preprocessed = array();
    $item_class = $this->itemClass;

    $total = $this->getNumber();
    for ($i = 0; $i < $total; $i++) {
      $item = $item_class::getOne($this->file);
      if ($item) {
        $this->parameters['namespace'] = $this->getNamespace($item);
        $wrapper = $item->getWrapperClass();
        $preprocessed[] = $object = new $wrapper($this->connection, $item, $this->parameters);
        $object->addRelationships();
        $this->addToDatabase($object, $object->getResources());
      }
    }

    return $preprocessed;
  }
}

interface IslandoraImportObjectInterface {
  /**
   * Get an item from the source.
   *
   * Extract one item from the source (modifying the source such that in no
   * longer contains the one being extracted).  Return an instantiation of
   * this class representing the one extracted from the source.
   *
   * Return NULL if there's none to get.
   */
  public static function getOne(&$source);
}

/**
 * A base object (MODS + DC) which can write itself out to Fedora.
 *
 * Might be a good idea to make use of static caching (using static variable)
 * within getter methods.
 *
 * @author adam@discoverygarden.ca
 */
abstract class IslandoraImportObject implements IslandoraImportObjectInterface {
  public $pidNamespace = 'ir';
  public $pidCacheSize = 2;

  /**
   * Allow subclasses to use different content models.
   * @var string
   */
  protected $contentModel = 'ir:citationCModel';

  /**
   * Used to store the source data in the default implementation.
   * @var mixed
   */
  protected $source;

  /**
   * Used for lazy-loading storage.
   * @var string|null
   */
  protected $dc = NULL;
  protected $title = NULL;

  /**
   * Private constructor.
   *
   * Instantiations should be obtained via the "getOne" static method, which
   * should know how to extract and feed what is needed to the constructor.
   *
   * Default implementation just saves the source.
   */
  protected function __construct($source) {
    $this->source = $source;
  }

  /**
   * Get the source text.
   */
  public function getSource() {
    return $this->source;
  }

  /**
   * Get the title.
   *
   * By default, should just get the first titleInfo/title out of the generated
   * MODS.
   *
   * @return string
   *   A string containing the title (eventually used as a label).
   */
  public function getTitle() {
    if ($this->title === NULL) {
      $mods = $this->getMODS();
      if ($mods) {
        $mods_doc = new DOMDocument();
        $mods_doc->loadXML($mods);
        $mods_xpath = new DOMXPath($mods_doc);
        $mods_xpath->registerNamespace('m', 'http://www.loc.gov/mods/v3');

        if ($mods_xpath->evaluate('string(//m:mods/m:titleInfo/m:title/text())')) {
          $this->title = $mods_xpath->evaluate('string(//m:mods/m:titleInfo/m:title/text())');
        }
        else {
          $this->title = pathinfo(reset($this->source['object_info']), PATHINFO_FILENAME);
        }
      }
    }

    return $this->title;
  }

  /**
   * Create some MODS representing us.
   *
   * Don't really care how it is obtained, as long as it's a string containing
   * MODS XML.  Statically caching your result may be a good idea, to avoid
   * regenerating it.
   *
   * @return string
   *   A string containing MODS XML.
   */
  public abstract function getMODS();

  /**
   * Create some DC representing us.
   *
   * Default implementation transforms MODS.
   *
   * @return string
   *   A string containing DC XML.
   */
  public function getDC() {
    if ($this->dc === NULL) {
      $new_dc = static::runXSLTransform(array(
                  'xsl' => drupal_get_path('module', 'islandora_importer') . '/xsl/mods_to_dc.xsl',
                  'input' => $this->getMODS(),
                ));
      if ($new_dc) {
        $this->dc = $new_dc;
      }
    }

    return $this->dc;
  }

  public function escapeSolrValue($string)
  {
    $match = array('\\', '+', '-', '&', '|', '!', '(', ')', '{', '}', '[', ']', '^', '~', '*', '?', ':', '"', ';', ' ');
    $replace = array('\\\\', '\\+', '\\-', '\\&', '\\|', '\\!', '\\(', '\\)', '\\{', '\\}', '\\[', '\\]', '\\^', '\\~', '\\*', '\\?', '\\:', '\\"', '\\;', '\\ ');
    $string = str_replace($match, $replace, $string);
     
    return $string;
  }

  public function checkMODS($xmlstring) {
      $error_IID_numbers = '';
      $iid_count = 0;

      // if there was no xml, this is a dummy MODS, so do not validate
      if (!isset($this->source['object_info']['xml'])) {
          return '';
      }

      // if parent is an intermediate serial object, do not validate
/*
      $parent_object = islandora_object_load($this->parentPid);
      if (in_array('islandora:intermediateCModel', $parent_object->models)) {
          return '';
      }
*/
      $mods_xml = new SimpleXMLElement($xmlstring);

      $namespaces = $mods_xml->getNameSpaces(true);

      // check for title
      $found_title = FALSE;
      if (isset($mods_xml->titleInfo->title)) {
          $found_title = TRUE;
      }
      if ($found_title == FALSE) {
          return 'Metadata has no title';
      }

      // check for owningInstitution
      $owning_institution = '';
      $found_owning_inst = FALSE;
      if (isset($namespaces['flvc'])) {
        foreach ($mods_xml->extension as $extension) {
          $flvc_entry = $extension->children($namespaces['flvc']);
          if ((count($flvc_entry) == 1)&&(isset($flvc_entry->flvc))) {
              $flvc_fields = $flvc_entry->flvc->children($namespaces['flvc']);
              if (isset($flvc_fields->owningInstitution)&&(strlen($flvc_fields->owningInstitution) > 0)) {
                  $owning_institution = trim($flvc_fields->owningInstitution);
                  $found_owning_inst = TRUE;
              }
          }
        }
      }
      if ($found_owning_inst == FALSE) {
          return 'Metadata has no owningInstitution';
      }

      //check for IID identifier
      if (isset($mods_xml->identifier)) {
              foreach ($mods_xml->identifier as $identifier) {
                if (isset($identifier['type'])&&(strcasecmp($identifier['type'], 'IID') == 0)&&(strlen(trim($identifier)) > 0)) {
                  $iid_count += 1;
                  $solr_url = "http://localhost:8080/solr/select/?version=2.2&start=0&rows=10&indent=on&fl=PID&wt=json&q=mods_identifier_iid_mls%3A" . urlencode($this->escapeSolrValue(trim($identifier)));
                  $results = file_get_contents($solr_url);
                  $solr_results = array();
                  if (isset($results)) {
                    $solr_results = json_decode($results, TRUE);
                    $numfound = $solr_results['response']['numFound'];
                    if ($numfound > 0) {
                      $error_IID_numbers = $error_IID_numbers . $identifier . ' ';
                    }
                  }
                }
              }
      }
      if ($iid_count == 0) {
          return 'Metadata has no IID identifier';
      }
      if (strlen($error_IID_numbers) > 0) {
          return 'The following IID identifiers already exist: ' . $error_IID_numbers;
      }

      // check format of purls
      $server_error_purls = '';
      $error_purls = '';
      foreach ($mods_xml->location as $location) {
        $url = $location->url;
        if (isset($location['displayLabel'])&&(strcasecmp($location['displayLabel'], 'purl') == 0)) {
            if ((strpos($url,'http://purl.flvc.org') === false)&&(strpos($url,'http://purl.fcla.edu') === false)) {
                $server_error_purls = $server_error_purls . $url . ' ';
            }
        }
        if ((strpos($url,'http://purl.flvc.org') !== false)||(strpos($url,'http://purl.fcla.edu') !== false)) {
            $purl_id = str_replace('http://purl.flvc.org','',str_replace('http://purl.fcla.edu','',$url));
            $hoststr = '/' . $owning_institution . '/';
            if (stripos($purl_id,$hoststr) !== 0) {
                $error_purls = $error_purls . $url . ' ';
            }
        }
      }
      if (strlen($server_error_purls) > 0) {
        return t('The following PURLs have incorrect server names: %badpurls', array('%badpurls' => $server_error_purls));
      }
      if (strlen($error_purls) > 0) {
        return t('Allowable PURL domains are %domains.  The following PURLs have incorrect formats: %badpurls', array('%domains' => $owning_institution, '%badpurls' =>$error_purls));
      }

      return '';
  }

  /**
   * Acquire base datastreams structure.
   *
   * Default implementation gets MODS and DC as inline-XML datastreams.
   *
   * @param array $errors
   *   A reference to an array of arrays describing errors which may occur,
   *   used to generate a watchdog entries and a simple HTML log which can be
   *   downloaded after the batch process completes.  Each contained array can
   *   contain four elements:
   *   - A translated string
   * @param array $files
   *   A reference to an array of Drupal file objects, which will be deleted
   *   after the ingest process completes (so temporary files can be dealt
   *   with). (Just seems to need ->uri?)
   *
   * @return array
   *   The array of datastreams as used by
   *   islandora_prepare_new_object().
   */
  protected function getDatastreams(&$errors = NULL, &$files = NULL) {
    $datastreams = array();

    // Ingest the MODS.
    $obtained_mods = $this->getMODS();
    if ($obtained_mods) {
      $IID_error = $this->checkMODS($obtained_mods);
      if (strlen($IID_error) > 0) {
          // if IID error, set error message and create dummy MODS datastream
          drupal_set_message(t($IID_error), 'error');
          $errors[] = array(
            t($IID_error),
          );
          $title = $this->getTitle();
          if (strlen($title) == 0) {
              $title = pathinfo(reset($this->source['object_info']), PATHINFO_FILENAME);
          }
          $obtained_mods = <<<EOXML
<mods xmlns="http://www.loc.gov/mods/v3">
  <titleInfo>
    <title>$title</title>
  </titleInfo>
</mods>
EOXML;
      }
      if ((isset($this->source['object_info']['xml']))&&(strlen($IID_error) == 0)) {
          // if incoming xml with no errors then run transform to create purls
          $copy_mods = $obtained_mods;
          $purltransform = drupal_get_path('module', 'xml_forms') . '/builder/self_transforms/FLVC_MODS_postprocessing.xsl';
          $obtained_mods = static::runXSLTransform(array('input' => $copy_mods, 'xsl' => $purltransform)); 
      }
      $name = file_create_filename('MODS record.xml', 'public://');
      $files[] = $file = file_save_data($obtained_mods, $name);
      $datastreams[] = array(
        'dsid' => 'MODS',
        'label' => 'MODS Record',
        'mimetype' => 'text/xml',
        'control_group' => 'M',
        'datastream_file' => file_create_url($file->uri),
        'file' => $file,
      );
    }
    else {
      $errors[] = array(
        t('Failed to produce MODS record for @pid.'),
      );
    }

    // Ingest the DC second.
    $obtained_dc = $this->getDC();
    if ($obtained_dc) {
      $name = file_create_filename('DC record.xml', 'public://');
      $files[] = $file = file_save_data($obtained_dc, $name);
      $datastreams[] = array(
        'dsid' => 'DC',
        'label' => 'DC Record',
        'mimetype' => 'text/xml',
        'control_group' => 'X',
        'datastream_file' => file_create_url($file->uri),
        'file' => $file,
      );
    }
    else {
      $errors[] = array(
        t('Failed to produce DC record for @pid.'),
      );
    }

    return $datastreams;
  }

  /**
   * Run an XSLT, and return the results.
   *
   * @param array $info
   *   An associative array of parameters, containing:
   *   - input: The input XML in a string.
   *   - xsl: The path to an XSLT file.
   *
   * @return string
   *   The transformed XML, as a string.
   */
  protected static function runXSLTransform($info) {
    $xsl = new DOMDocument();
    $xsl->load($info['xsl']);

    $input = new DOMDocument();
    $input->loadXML($info['input']);

    $processor = new XSLTProcessor();
    $processor->importStylesheet($xsl);

    return $processor->transformToXML($input);
  }

  /**
   * Accessor for content models.
   */
  public function getContentModels() {
    return (array) $this->contentModel;
  }

  /**
   * Expose results of getDatastreams without breaking interface.
   */
  final public function getDatastreamInfo() {
    $errors = array();
    $files = array();
    $datastreams = $this->getDatastreams($errors, $files);
    return array(
      $datastreams,
      $errors,
      $files,
    );
  }

  /**
   * Add relationships to the given object being created.
   */
  public function modifyRelationships(AbstractObject $object) {
    $object->models = $this->getContentModels();
  }

  /**
   * Get the name of the class which wraps this.
   *
   * Should be a subclass of IslandoraImporterBatchObject.
   *
   * @return string
   *   The name of class.
   */
  public function getWrapperClass() {
    return 'IslandoraImporterBatchObject';
  }
}

class IslandoraImporterBatchObject extends IslandoraBatchObject {
  protected $importerObjectInstance = NULL;
  protected $preprocessorParameters = array();

  /**
   * Constructor.
   */
  public function __construct(IslandoraTuque $connection, IslandoraImportObject $object, $preprocessor_parameters = array()) {
    parent::__construct(NULL, $connection->repository);
    $this->importerObjectInstance = $object;
    $this->preprocessorParameters = $preprocessor_parameters;
  }

  /**
   * Inherited.
   */
  public function batchProcess() {
    $this->label = $this->importerObjectInstance->getTitle();
    list($datastreams, $errors, $files) = $this->importerObjectInstance->getDatastreamInfo();
    foreach ($files as $file) {
      $file->status &= ~FILE_STATUS_PERMANENT;
      file_save($file);
      file_usage_add($file, 'islandora_batch', 'islandora_batch_object', $this->getBatchId());
    }
    foreach ($datastreams as $ds) {
      $ds_uri = isset($ds['file']) ?
        $ds['file']->uri :
        $ds['datastream_file'];

      $datastream = $this->constructDatastream($ds['dsid'], $ds['control_group']);
      $datastream->label = $ds['label'];
      $datastream->mimetype = $ds['mimetype'];
      $datastream->setContentFromFile($ds_uri);
      $this->ingestDatastream($datastream);
    }

    $parent_object = islandora_object_load($this->preprocessorParameters['parent_pid']);
    if ($parent_object['POLICY']) {
        $this->relationships->add(ISLANDORA_RELS_EXT_URI, 'inheritXacmlFrom', $parent_object, RELS_TYPE_URI);
        $this->importerObjectInstance->modifyRelationships($this);
        $xacml = new IslandoraXacml($this, $parent_object['POLICY']->content);
        $xacml->writeBackToFedora();
    }

    foreach ($files as $file) {
        if ($file) {
            file_usage_delete($file, 'islandora_batch', 'islandora_batch_object', $this->getBatchId());
            file_delete($file);
        }
    }

    return ISLANDORA_BATCH_STATE__DONE;
  }

  /**
   * Inherited.
   */
  public function getResources() {
    return array();
  }

  /**
   * Inherited.
   */
  public function addRelationships() {
    $this->relationships->add(FEDORA_RELS_EXT_URI, 'isMemberOfCollection', $this->preprocessorParameters['parent_pid']);
    $this->importerObjectInstance->modifyRelationships($this);
  }
}
