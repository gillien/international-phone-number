# Author Marek Pietrucha
# https://github.com/mareczek/international-phone-number

"use strict"
angular.module("internationalPhoneNumber", [])

.constant 'ipnConfig', {
    allowExtensions:        false
    autoFormat:             true
    autoHideDialCode:       true
    separateDialCode:       false
    modelWithDialCode:      false
    autoPlaceholder:        true
    customPlaceholder:      null
    defaultCountry:         ''
    nationalMode:           true
    numberType:             'MOBILE'
    onlyCountries:          undefined
    preferredCountries:     ['us', 'gb']
    skipUtilScriptDownload: false
    utilsScript:            ''
  }

.directive 'internationalPhoneNumber', ['$timeout', 'ipnConfig', ($timeout, ipnConfig) ->

  restrict:   'A'
  require: '^ngModel'
  scope:
    ngModel: '='
    country: '='

  link: (scope, element, attrs, ctrl) ->
    if ctrl
      if element.val() != ''
        $timeout () ->
          element.intlTelInput 'setNumber', element.val()
          ctrl.$setViewValue element.val()

    read = () ->
      ctrl.$setViewValue element.val()
      if !scope.$$phase && !scope.$root.$$phase
        scope.$apply

    handleWhatsSupposedToBeAnArray = (value) ->
      if value instanceof Array
        value
      else
        value.toString().replace(/[ ]/g, '').split(',')

    options = angular.copy(ipnConfig)

    angular.forEach options, (value, key) ->
      return unless attrs.hasOwnProperty(key) and angular.isDefined(attrs[key])
      option = attrs[key]
      if key == 'preferredCountries'
        options.preferredCountries = handleWhatsSupposedToBeAnArray option
      else if key == 'onlyCountries'
        options.onlyCountries = handleWhatsSupposedToBeAnArray option
      else if typeof(value) == 'boolean'
        options[key] = (option == 'true')
      else
        options[key] = option

    # Wait for ngModel to be set
    watchOnce = scope.$watch('ngModel', (newValue) ->
      # Wait to see if other scope variables were set at the same time
      scope.$$postDigest ->

        if newValue != null && newValue != undefined && newValue.length > 0

          if newValue[0] != '+'
            newValue = '+' + newValue

          ctrl.$modelValue = newValue
          element.val newValue

        element.intlTelInput options

        unless options.skipUtilScriptDownload || attrs.skipUtilScriptDownload != undefined || options.utilsScript
          element.intlTelInput 'loadUtils', '/bower_components/intl-tel-input/build/js/utils.js'

        watchOnce()
    )

    scope.$watch('country', (newValue) ->
      if newValue != null && newValue != undefined && newValue != ''
        element.intlTelInput 'setCountry', newValue
    )

    ctrl.$formatters.push (value) ->
      if !value
        return value

      element.intlTelInput 'setNumber', value
      element.val()

    ctrl.$parsers.push (value) ->
      if !value
        return value

      value = value.replace(/[^\d]/g, '')
      if options.modelWithDialCode
        selectedCountryData = element.intlTelInput 'getSelectedCountryData'
        dialCode = selectedCountryData?.dialCode
        '+' + dialCode + value
      else
        value

    ctrl.$validators.internationalPhoneNumber = (value) ->
      selectedCountry = element.intlTelInput('getSelectedCountryData')

      if !value || (selectedCountry && selectedCountry.dialCode == value)
        return true

      element.intlTelInput 'isValidNumber'

    element.on 'blur keyup change', () ->
      read()

    element.on 'countrychange', () ->
      # force $parser re-run
      ctrl.$setViewValue null
      read()

    element.on '$destroy', () ->
      element.intlTelInput 'destroy'
      element.off 'blur keyup change'
      element.off 'countrychange'
]
