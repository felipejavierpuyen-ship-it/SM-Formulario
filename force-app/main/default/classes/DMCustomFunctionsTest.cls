@isTest
private class DMCustomFunctionsTest {
    @testSetup
    static void setupData() {
        // País
        SM_Poblacion__c pais = new SM_Poblacion__c(Name = 'Colombia', Codigo_poblacion__c = '1');
        insert pais;

        // Departamento
        SM_Poblacion__c dpto = new SM_Poblacion__c(
            Name = 'Amazonas', 
            SFC_Codigo__c = '91', 
            SM_PoblacionPrincipal__c = pais.Id
        );
        insert dpto;

        // Ciudad
        SM_Poblacion__c ciudad = new SM_Poblacion__c(
            Name = 'Leticia', 
            SFC_Codigo__c = '91536', 
            SM_Activo__c = true,
            SM_EsCiudad__c = true,
            SM_PoblacionPrincipal__c = dpto.Id
        );
        insert ciudad;

        // Intermediario - Account
        Account inter = new Account(Name = 'Agente Test', cod_agente__c = '13158');
        insert inter;

        // Sucursal
        SM_Sucursal__c sucursal = new SM_Sucursal__c(Name = 'Sucursal Central', SM_Codigo__c = 14);
        insert sucursal;

        // Caso
        Id csArriendoRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Solicitud_de_Arriendos').getRecordTypeId();
        Case cs = new Case(
            Subject = 'Caso Test Temporario',
            Canon__c = 1000,
            Valor_Administraci_n__c = 500,
            Description = 'Garantizar cumplimiento',
            DireccionInmueble__c = 'Calle Falsa 123',
            Telefono_tomador__c = '1234567',
            Moneda__c = 'EUR',
            Ramo__c = 'Arriendos',
            RecordTypeId = csArriendoRT,
            Sucursal__c = sucursal.Id,
            Intermediario__c = inter.Id,
            Fecha_inicio_de_vigencia_de_poliza__c = Date.today(),
            Fecha_fin_de_vigencia_de_poliza__c = Date.today().addYears(1),
            ObservacionesEmision__c = 'Test Obs'
        );
        insert cs;

        // Slip
        Id slipArriendoRT = Schema.SObjectType.Slip__c.getRecordTypeInfosByDeveloperName().get('RT_Arriendos').getRecordTypeId();
        Slip__c slip = new Slip__c(
            RecordTypeId = slipArriendoRT,
            Caso__c = cs.Id,
            Ciudad__c = ciudad.Id,
            Aplica_apropiacion__c = true,
            Codigo_modalidad_de_aseguramiento__c = '1',
            Estado_riesgo__c = 'I',
            Grupo_de_endoso__c = '1',
            Codigo_de_destino_del_inmueble__c = '1',
            Indica_si_aplica_multiples_pagadores__c = false,
            Indica_si_aplica_renovacion_automatica__c = false,
            Indica_si_se_aplica_cobro_de_IVA__c = true,
            Indica_si_se_valida_la_prima_minima__c = true,
            Numero_de_articulos_en_el_inventario__c = 0,
            Numero_de_servicios_publicos__c = 0,
            Punto_de_venta__c = '0',
            Participacion_intermediario__c = 100,
            Renovacion_automatica__c = true,
            Tasa_de_cambio__c = 1,
            Tipo_de_endoso__c = '1',
            Tipo_de_intermediario__c = '1',
            Producto__c = '94',
            Tipo_de_Poliza__c = '3',
            Giro_de_negocio__c = '10',
            Tipo_IVA__c = '1',
            Valor_gastos_de_emisi_n__c = 1000000,
            Coberturas__c = '[{"Id":"01t1","NOMBRE":"CANON"}]'
        );
        insert slip;

        Id personAccRT =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        // Person Account 1
        Account personAcc1 = new Account(
            FirstName = 'Juan',
            LastName = 'Perez',
            PersonEmail = 'test@mail.com',
            Phone = '300123',
            SM_Direccion__c = 'Carrera 1',
            SM_Ciudad__c = ciudad.Id,
            SM_CorreoElectronico__c = 'segurosmundial@colombia.com',
            RecordTypeId = personAccRT
        );
        insert personAcc1;

        // Participantes de Póliza 1
        Participante_de_Poliza__c part1 = new Participante_de_Poliza__c(
            Caso_Relacionado__c = cs.Id,
            Cliente__c = personAcc1.Id,
            Cedula_o_NIT__c = '12345',
            Tipo_de_Participante__c = 'Inquilino',
            Tipo_de_Documento__c = 'Cédula de ciudadanía',
            EsTomador__c = true
        );
        insert part1;
        
        // Person Account
        Account personAcc2 = new Account(
            FirstName = 'Felipe',
            LastName = 'Puyen',
            PersonEmail = 'felipejavierpuyen@gmail.com',
            Phone = '+51957547079',
            SM_Direccion__c = 'Carrera 4',
            SM_Ciudad__c = ciudad.Id,
            SM_CorreoElectronico__c = 'felipejavierpuyen@gmail.com',
            RecordTypeId = personAccRT
        );
        insert personAcc2;
        
        // Participantes de Póliza 2
        Participante_de_Poliza__c part2 = new Participante_de_Poliza__c(
            Caso_Relacionado__c = cs.Id,
            Cliente__c = personAcc2.Id,
            Cedula_o_NIT__c = '77387641',
            Tipo_de_Participante__c = 'Deudor',
            Tipo_de_Documento__c = 'Cédula de ciudadanía',
            EsTomador__c = false
        );
        insert part2;
    }

    @isTest
    static void testSplitToObjectsFlexible_Success() {
        // 1. Preparación (Arrange): Simulamos la estructura exacta que envía el Data Mapper
        DMCustomFunctions customFunc = new DMCustomFunctions();
        
        // Simulamos los 3 parámetros que le pasas en la fórmula
        List<Object> arguments = new List<Object>{
            'Pérdidas Patrimoniales ; Asistencia en viaje', // 1. El texto a separar
            ';',                                            // 2. El separador
            'Nombre'                                        // 3. El nombre de la llave
        };
        
        // Construimos los mapas requeridos por la interfaz Callable de OmniStudio
        Map<String, Object> inputMap = new Map<String, Object>{ 'arguments' => arguments };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => outputMap,
            'options' => optionsMap
        };

        // 2. Ejecución (Act): Llamamos al método principal "call"
        Test.startTest();
        // El primer parámetro de call() suele ser el nombre del método
        customFunc.call('splitToObjectsFlexible', args);
        Test.stopTest();

        // 3. Verificación (Assert): Comprobamos que el resultado se guardó en el mapa "output"
        System.assert(outputMap.containsKey('result'), 'El mapa output debería contener la llave "result" generada por el método.');
        
        List<Map<String, Object>> resultList = (List<Map<String, Object>>) outputMap.get('result');
        System.assertEquals(2, resultList.size(), 'Debería haber 2 objetos en la lista generada.');
        
        // Verificamos que se haya limpiado el espacio en blanco (trim) y se haya asignado la llave correcta
        System.assertEquals('Pérdidas Patrimoniales', resultList[0].get('Nombre'), 'El primer elemento no coincide.');
        System.assertEquals('Asistencia en viaje', resultList[1].get('Nombre'), 'El segundo elemento no coincide o tiene espacios extra.');
    }

    @isTest
    static void testSplitToObjectsFlexible_NullInputs() {
        // Prueba de estrés: ¿Qué pasa si el Data Mapper envía el campo vacío o faltan parámetros?
        DMCustomFunctions customFunc = new DMCustomFunctions();
        
        // Caso A: Parámetros incompletos o campo nulo
        List<Object> arguments = new List<Object>{ null, ';', 'Nombre' };
        Map<String, Object> inputMap = new Map<String, Object>{ 'arguments' => arguments };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        Test.startTest();
        customFunc.invokeMethod('splitToObjectsFlexible', inputMap, outputMap, optionsMap);
        Test.stopTest();
        
        // Verificamos que devuelva una lista vacía y no rompa con un NullPointerException
        List<Map<String, Object>> resultList = (List<Map<String, Object>>) outputMap.get('result');
        System.assertEquals(0, resultList.size(), 'La lista debe estar vacía si el valor de entrada es nulo.');
    }

    @isTest
    static void testUnknownMethod() {
        // Prueba para garantizar la cobertura de la condición donde no se encuentra el método
        DMCustomFunctions customFunc = new DMCustomFunctions();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        Test.startTest();
        Boolean isSuccess = customFunc.invokeMethod('unMetodoQueNoExiste', inputMap, outputMap, optionsMap);
        Test.stopTest();
        
        // El método invokeMethod original de Vlocity devuelve true al final por defecto
        System.assertEquals(true, isSuccess, 'Debe retornar true según el estándar de la plantilla.');
        System.assertEquals(false, outputMap.containsKey('result'), 'No debe generarse un result para un método desconocido.');
    }

    @isTest
    static void testGetFormatParticipantsSuccess() {
        Slip__c slip = [SELECT Id FROM Slip__c LIMIT 1];
        
        DMCustomFunctions customFunc = new DMCustomFunctions();
        List<Object> arguments = new List<Object>{
            slip.Id
        };
        
        Map<String, Object> inputMap = new Map<String, Object>{ 'arguments' => arguments };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => outputMap,
            'options' => optionsMap
        };

        Test.startTest();
        customFunc.call('getFormatParticipants', args);
        Test.stopTest();

        List<Map<String, Object>> resultList = (List<Map<String, Object>>) outputMap.get('result');
        // Debería haber 4 roles por el Participante: AFIANZADO, INQUILINO, ARRENDATARIO y TOMADOR (porque EsTomador__c = true)
        System.assertEquals(4, resultList.size(), 'Se esperaban 4 roles para el participante configurado');
    }

    @isTest
    static void testSafeIntegerError() {
        SM_Poblacion__c pais = [SELECT Id, Name, Codigo_poblacion__c 
                                FROM SM_Poblacion__c 
                                WHERE Name ='Colombia'
                                LIMIT 1];
        pais.Codigo_poblacion__c = 'col';
        update pais;

        Slip__c slip = [SELECT Id FROM Slip__c LIMIT 1];
        
        DMCustomFunctions customFunc = new DMCustomFunctions();
        List<Object> arguments = new List<Object>{
            slip.Id
        };
        
        Map<String, Object> inputMap = new Map<String, Object>{ 'arguments' => arguments };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => outputMap,
            'options' => optionsMap
        };

        Test.startTest();
        customFunc.call('getFormatParticipants', args);
        Test.stopTest();

        List<Map<String, Object>> resultList = (List<Map<String, Object>>) outputMap.get('result');
        // Muestra los 4 roles, el catch controla el error
        System.assertEquals(4, resultList.size(), 'Se esperaban 4 roles para el participante configurado');
    }
}