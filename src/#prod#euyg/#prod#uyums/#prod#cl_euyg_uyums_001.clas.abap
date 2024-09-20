CLASS /prod/cl_euyg_uyums_001 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-DATA:
      url  TYPE string,
      body TYPE /prod/euyg_uyums_s_05.

    INTERFACES if_oo_adt_classrun .

    METHODS constructor .

  PROTECTED SECTION.

    METHODS set_url.

    METHODS set_body.

    METHODS set_body_page
      IMPORTING page TYPE int4.

    METHODS get_json_req
      RETURNING
        VALUE(json_req) TYPE string.

    METHODS service_execute
      IMPORTING
        json_req      TYPE string
      EXPORTING
        json_response TYPE string.

    METHODS save_response
      IMPORTING
        json_response TYPE string
      EXPORTING
        total_pages   TYPE int4.

  PRIVATE SECTION.

ENDCLASS.


CLASS /prod/cl_euyg_uyums_001 IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA:
      lv_total_pages TYPE int4,
      lv_page        TYPE int4 VALUE 0,
      json_response  TYPE string,
      json_req       TYPE string.

    CLEAR json_response.

    DO.

      me->set_body_page( lv_page ).

      json_req = me->get_json_req( ).

      CALL METHOD me->service_execute
        EXPORTING
          json_req      = json_req
        IMPORTING
          json_response = json_response.

      CALL METHOD me->save_response
        EXPORTING
          json_response = json_response
        IMPORTING
          total_pages   = lv_total_pages.

      lv_page += 1.

      IF lv_page EQ lv_total_pages.
        EXIT.
      ENDIF.

    ENDDO.

  ENDMETHOD.

  METHOD set_body.

    me->body-action                           = 'GetEInvoiceUsers'.
    me->body-parameters-user_info-username    = 'Uyumsoft'.
    me->body-parameters-user_info-password    = 'Uyumsoft'.
    me->body-parameters-pagination-pagesize   = '1000'.

  ENDMETHOD.

  METHOD get_json_req.

    /ui2/cl_json=>serialize(
      EXPORTING
        data             =  me->body
        pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
      RECEIVING
        r_json           = json_req
        ).

  ENDMETHOD.

  METHOD service_execute.

    DATA:
      http_client TYPE REF TO if_web_http_client.

    TRY.

        http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = cl_http_destination_provider=>create_by_url( i_url = me->url ) ).

        DATA(lo_request) = http_client->get_http_request(   ).

        lo_request->set_header_field( i_name =  'Content-Type'
                                      i_value = 'application/json' ).

        lo_request->set_text( json_req ).

        DATA(response) = http_client->execute( if_web_http_client=>post ).

        DATA(status) = response->get_status( ).

        IF status-code EQ 200.

          json_response = response->get_text( ).

        ENDIF.

        http_client->close(  ).

        FREE http_client.

      CATCH cx_web_http_client_error cx_http_dest_provider_error.
        "Handle exception here.

    ENDTRY.

  ENDMETHOD.

  METHOD set_url.
    me->url = 'https://efatura-test.uyumsoft.com.tr/api/BasicIntegrationApi'.
  ENDMETHOD.

  METHOD constructor.

    me->set_url( ).
    me->set_body( ).

  ENDMETHOD.

  METHOD set_body_page.
    me->body-parameters-pagination-pageindex  = page.
  ENDMETHOD.

  METHOD save_response.

    DATA:
      ls_fin TYPE /prod/euyg_uyums_s_01,
      lt_fin TYPE /prod/euyg_uyums_tt_01.

    CLEAR lt_fin.

    /ui2/cl_json=>deserialize(
       EXPORTING
       json = json_response
       CHANGING
       data = ls_fin
       ).

    lt_fin[] = ls_fin-data-value-items[].


  ENDMETHOD.

ENDCLASS.
