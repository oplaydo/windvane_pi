##---------------------------------------------------------------------------
## Author:      Pavel Kalian / Sean D'Epagnier
## Copyright:   
## License:     GPLv3+
##---------------------------------------------------------------------------

MESSAGE(STATUS "Starting POTFILE generation")

SET(POTFILE ${CMAKE_CURRENT_SOURCE_DIR}/po/POTFILES.in)
FILE(REMOVE ${POTFILE}.test)
FOREACH(POTLINE IN ITEMS ${SRCS})
    FILE(APPEND ${POTFILE}.test "${POTLINE}\n")
ENDFOREACH(POTLINE)
FOREACH(POTLINE IN ITEMS ${HDRS})
    FILE(APPEND ${POTFILE}.test "${POTLINE}\n")
ENDFOREACH(POTLINE)
# convert crlf to lf for consistency and make copy_if_different work correctly
configure_file(${POTFILE}.test ${POTFILE}.test NEWLINE_STYLE UNIX)
EXECUTE_PROCESS(
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${POTFILE}.test ${POTFILE}
    OUTPUT_QUIET
    ERROR_QUIET
)

FIND_PROGRAM(GETTEXT_XGETTEXT_EXECUTABLE xgettext)
string(REPLACE "_pi" "" I18N_NAME ${PACKAGE_NAME})
IF (GETTEXT_XGETTEXT_EXECUTABLE)
  MESSAGE(STATUS "Doing XGETTEXT")
  ADD_CUSTOM_COMMAND(
    OUTPUT po/${PACKAGE_NAME}.pot.dummy
    COMMAND ${GETTEXT_XGETTEXT_EXECUTABLE} --force-po -F --from-code=UTF-8 --package-name=${PACKAGE_NAME} --package-version="${PACKAGE_VERSION}" --output=po/${PACKAGE_NAME}.pot  --keyword=_ --width=80 --files-from=${CMAKE_CURRENT_SOURCE_DIR}/po/POTFILES.in
    DEPENDS po/POTFILES.in po/${PACKAGE_NAME}.pot
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "${I18N_NAME}-pot-update [${PACKAGE_NAME}]: Generated pot file."
    )
  ADD_CUSTOM_TARGET(${I18N_NAME}-pot-update COMMENT "[${PACKAGE_NAME}]-pot-update: Done." DEPENDS po/${PACKAGE_NAME}.pot.dummy)

ENDIF(GETTEXT_XGETTEXT_EXECUTABLE )

MACRO(GETTEXT_UPDATE_PO _potFile)
  SET(_poFiles ${_potFile})
  GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)

  FOREACH (_currentPoFile ${ARGN})
    GET_FILENAME_COMPONENT(_absFile ${_currentPoFile} ABSOLUTE)
    GET_FILENAME_COMPONENT(_poBasename ${_absFile} NAME_WE)

    ADD_CUSTOM_COMMAND(
      OUTPUT ${_absFile}.dummy 
      COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --width=80 --strict --quiet --update --backup=none --no-location -s ${_absFile} ${_absPotFile}
      DEPENDS ${_absPotFile} ${_absFile}
      COMMENT "${I18N_NAME}-po-update [${_poBasename}]: Updated po file."
      )

    SET(_poFiles ${_poFiles} ${_absFile}.dummy)

  ENDFOREACH (_currentPoFile )

  ADD_CUSTOM_TARGET(${I18N_NAME}-po-update COMMENT "[${PACKAGE_NAME}]-po-update: Done." DEPENDS ${_poFiles})
ENDMACRO(GETTEXT_UPDATE_PO)

IF (GETTEXT_MSGMERGE_EXECUTABLE)
  FILE(GLOB PACKAGE_PO_FILES po/*.po)
  GETTEXT_UPDATE_PO(po/${PACKAGE_NAME}.pot ${PACKAGE_PO_FILES})
ENDIF(GETTEXT_MSGMERGE_EXECUTABLE)

SET(_gmoFiles)
MACRO(GETTEXT_BUILD_MO)
  FOREACH (_poFile ${ARGN})
    GET_FILENAME_COMPONENT(_absFile ${_poFile} ABSOLUTE)
    GET_FILENAME_COMPONENT(_poBasename ${_absFile} NAME_WE)
    SET(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_poBasename}.mo)

    ADD_CUSTOM_COMMAND(
      OUTPUT ${_gmoFile}
      COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} --check -o ${_gmoFile} ${_absFile}
      COMMAND ${CMAKE_COMMAND} -E copy ${_gmoFile} "Resources/${_poBasename}.lproj/opencpn-${PACKAGE_NAME}.mo"
      DEPENDS ${_absFile}
      COMMENT "${I18N_NAME}-i18n [${_poBasename}]: Created mo file."
      )

    IF(APPLE)
      INSTALL(FILES ${_gmoFile} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin/OpenCPN.app/Contents/Resources/${_poBasename}.lproj RENAME opencpn-${PACKAGE_NAME}.mo )
    ELSE(APPLE)
      INSTALL(FILES ${_gmoFile} DESTINATION ${PREFIX_DATA}/locale/${_poBasename}/LC_MESSAGES RENAME opencpn-${PACKAGE_NAME}.mo )
      MESSAGE (STATUS "Install language files to: ${PREFIX_DATA}/locale/${_poBasename}/LC_MESSAGES renamed to: opencpn-${PACKAGE_NAME}.mo")
    ENDIF(APPLE)

    SET(_gmoFiles ${_gmoFiles} ${_gmoFile})
  ENDFOREACH (_poFile )
ENDMACRO(GETTEXT_BUILD_MO)

if(GETTEXT_MSGFMT_EXECUTABLE)
  FILE(GLOB PACKAGE_PO_FILES po/*.po)
  GETTEXT_BUILD_MO(${PACKAGE_PO_FILES})
  ADD_CUSTOM_TARGET(${I18N_NAME}-i18n COMMENT "${PACKAGE_NAME}-i18n: Done." DEPENDS ${_gmoFiles})
  ADD_DEPENDENCIES(${PACKAGE_NAME} ${I18N_NAME}-i18n)
ENDIF(GETTEXT_MSGFMT_EXECUTABLE)
