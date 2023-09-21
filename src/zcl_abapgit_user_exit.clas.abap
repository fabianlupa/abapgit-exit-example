CLASS zcl_abapgit_user_exit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_abapgit_exit.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF actions,
        launch_standalone TYPE string VALUE 'zlaunch',
      END OF actions.
ENDCLASS.


CLASS zcl_abapgit_user_exit IMPLEMENTATION.
  METHOD zif_abapgit_exit~adjust_display_commit_url.
  ENDMETHOD.

  METHOD zif_abapgit_exit~adjust_display_filename.
  ENDMETHOD.

  METHOD zif_abapgit_exit~allow_sap_objects.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_local_host.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_proxy_authentication.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_proxy_port.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_proxy_url.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_supported_data_objects.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_supported_object_types.
  ENDMETHOD.

  METHOD zif_abapgit_exit~change_tadir.
  ENDMETHOD.

  METHOD zif_abapgit_exit~create_http_client.
  ENDMETHOD.

  METHOD zif_abapgit_exit~custom_serialize_abap_clif.
  ENDMETHOD.

  METHOD zif_abapgit_exit~deserialize_postprocess.
  ENDMETHOD.

  METHOD zif_abapgit_exit~determine_transport_request.
  ENDMETHOD.

  METHOD zif_abapgit_exit~enhance_repo_toolbar.
  ENDMETHOD.

  METHOD zif_abapgit_exit~get_ci_tests.
  ENDMETHOD.

  METHOD zif_abapgit_exit~get_ssl_id.
  ENDMETHOD.

  METHOD zif_abapgit_exit~http_client.
  ENDMETHOD.

  METHOD zif_abapgit_exit~on_event.
    DATA program  TYPE progname.
    DATA repo_key TYPE rfc_spagpa-parval.

    CASE ii_event->mv_action.
      WHEN actions-launch_standalone.
        program = ii_event->query( )->get( 'program' ).
        repo_key = ii_event->query( )->get( 'repo' ).
        IF program IS INITIAL OR repo_key IS INITIAL OR program NP 'ZABAPGIT_STANDALONE*'.
          zcx_abapgit_exception=>raise( |Unknown jump location for { ii_event->mv_action }| ).
        ENDIF.

        SET PARAMETER ID zif_abapgit_definitions=>c_spagpa_param_repo_key
            FIELD repo_key.
        SUBMIT (program) AND RETURN.
        MESSAGE |Returned from { program }| TYPE 'S'.

        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
    ENDCASE.

    " Override page transition from repo overview to repo page
    IF NOT ( ii_event->mv_current_page_name = 'ZCL_ABAPGIT_GUI_PAGE_REPO_OVER' AND ii_event->mv_action = 'select' ).
      RETURN.
    ENDIF.

    repo_key = EXACT #( ii_event->query( )->get( 'key' ) ).
    DATA(repo) = zcl_abapgit_repo_srv=>get_instance( )->get( EXACT #( repo_key ) ).
    IF repo->is_offline( ).
      RETURN.
    ENDIF.

    DATA(online_repo) = CAST zcl_abapgit_repo_online( repo ).
    DATA(full_name) = to_lower(
        condense( cl_http_utility=>unescape_url( zcl_abapgit_url=>path_name( online_repo->get_url( ) ) ) ) ).

    program = SWITCH #( full_name
                        WHEN '/fabianlupa/abapgit-exit-example'
                        THEN 'ZABAPGIT_STANDALONE_20230802' ).
    IF program IS INITIAL.
      RETURN.
    ENDIF.

    DATA(answer) = zcl_abapgit_ui_factory=>get_popups( )->popup_to_confirm(
                       iv_titlebar      = 'Redirect'
                       iv_text_question = |You will be redirected to program { program } for this repository.|
                       iv_icon_button_1 = CONV #( icon_okay )
                       iv_text_button_1 = 'Continue'
                       iv_text_button_2 = 'Open here' ).
    CASE answer.
      WHEN '1'.
        SET PARAMETER ID zif_abapgit_definitions=>c_spagpa_param_repo_key
            FIELD repo_key.
        SUBMIT (program) AND RETURN.
        MESSAGE |Returned from { program }| TYPE 'S'.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN '2'.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-not_handled.
      WHEN 'A'.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_abapgit_exit~pre_calculate_repo_status.
  ENDMETHOD.

  METHOD zif_abapgit_exit~serialize_postprocess.
  ENDMETHOD.

  METHOD zif_abapgit_exit~validate_before_push.
  ENDMETHOD.

  METHOD zif_abapgit_exit~wall_message_list.
  ENDMETHOD.

  METHOD zif_abapgit_exit~wall_message_repo.
    DATA full_name TYPE string.

    TRY.
        IF    is_repo_meta-offline = abap_true
           OR to_lower( zcl_abapgit_url=>host( is_repo_meta-url ) ) <> 'https://github.com'.
          RETURN.
        ENDIF.
        full_name = to_lower(
                        condense( cl_http_utility=>unescape_url( zcl_abapgit_url=>path_name( is_repo_meta-url ) ) ) ).
      CATCH zcx_abapgit_exception INTO DATA(exception).
        ii_html->add( |<div class="panel error">Error parsing URL { is_repo_meta-url }: | &&
                      |{ exception->get_text( ) }</div>| ).
        RETURN.
    ENDTRY.

    CASE full_name.
      WHEN '/fabianlupa/abapgit-exit-example'.
        ii_html->add( |<hr/>| ).
        ii_html->add( |<span>| ).
        ii_html->add_icon( 'info-circle-solid/blue' ).
        ii_html->add( |Please use the abapGit standalone version for this repo for now| ).
        ii_html->add_a( iv_txt   = 'Link'
                        iv_act   = actions-launch_standalone
                        iv_query = |program=ZABAPGIT_STANDALONE_20230802&repo={ is_repo_meta-key }| ).
        ii_html->add( |</span>| ).
        ii_html->add( |<hr/>| ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
