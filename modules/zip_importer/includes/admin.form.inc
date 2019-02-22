<?php

/**
 * @file
 * Handles the display/submission of the admin settings form for this module.
 */

/**
 * Defines the admin settings form.
 *
 * @param array $form
 *   The Drupal form definition.
 * @param array $form_state
 *   The Drupal form state.
 *
 * @return array
 *   The Drupal form definition.
 */
function zip_importer_admin_settings_form(array $form, array &$form_state) {
  $get_default_value = function($name, $default) use(&$form_state) {
    return isset($form_state['values'][$name]) ? $form_state['values'][$name] : variable_get($name, $default);
  };
  $form = array(
    'zip_importer_use_filenames_as_labels' => array(
      '#type' => 'checkbox',
      '#title' => t('Use filename as Datastream label'),
      '#description' => t('If set uploaded files will use their filename as the label of the datastream they represent. Note that some files that get transformed like MARC to MODS will be ignored.'),
      '#default_value' => variable_get('zip_importer_use_filenames_as_labels', FALSE),
    ),
    'zip_importer_offline_ingest' => array(
      '#type' => 'fieldset',
      '#title' => t('Offline Ingest'),
      'zip_importer_offline_ingest_enabled' => array(
        '#type' => 'checkbox',
        '#title' => t('Use offline ingest for zip import of videos'),
        '#default_value' => $get_default_value('zip_importer_offline_ingest_enabled', FALSE),
      ),
      'zip_importer_offline_ingest_package_path_source' => array(
        '#type' => 'textfield',
        '#title' => t('Path of source directory'),
        '#description' => t('Enter path of source directory.'),
        '#default_value' => $get_default_value('zip_importer_offline_ingest_package_path_source', 'temporary://'),
        '#states' => array(
          'invisible' => array(
            ':input[name="zip_importer_offline_ingest_enabled"]' => array('checked' => FALSE),
          ),
        ),
      ),
      'zip_importer_offline_ingest_package_path_target' => array(
        '#type' => 'textfield',
        '#title' => t('Path of target directory'),
        '#description' => t('Enter path of target directory.'),
        '#default_value' => $get_default_value('zip_importer_offline_ingest_package_path_target', ''),
        '#states' => array(
          'invisible' => array(
            ':input[name="zip_importer_offline_ingest_enabled"]' => array('checked' => FALSE),
          ),
        ),
      ),
      'zip_importer_offline_ingest_options' => array(
        '#type' => 'textfield',
        '#title' => t('Additional options'),
        '#description' => t('Enter additional options.'),
        '#default_value' => $get_default_value('zip_importer_offline_ingest_options', ''),
        '#states' => array(
          'invisible' => array(
            ':input[name="zip_importer_offline_ingest_enabled"]' => array('checked' => FALSE),
          ),
        ),
      ),
    ),
  );
  return system_settings_form($form);
}
