import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getShareholders from '@salesforce/apex/WizardArriendosController.getShareholders';
const COLUMNS = [
    {   label: 'Nombre del Cliente', fieldName: 'Nombre_del_Cliente__c', 
        type: 'text', initialWidth: 230
    },
    {   label: 'Tipo de documento', fieldName: 'Tipo_de_Documento__c',
        type: 'text', initialWidth: 150 
    },
    {   label: 'Nro documento', fieldName: 'Cedula_o_NIT__c',
        type: 'text', initialWidth: 150 
    },
    {   label: '% de Participación', fieldName: 'de_Participacion__c',
        type: 'percent', initialWidth: 150, typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2'
        }, cellAttributes: { alignment: 'left' }
    },
    {   label: '¿Cotiza en bolsa?', fieldName: 'Cotiza_en_bolsa__c', 
        type: 'text', initialWidth: 140
    },
    {   label: '¿Es PEP?', fieldName: 'Es_PEP__c', 
        type: 'text', initialWidth: 100
    },
    {   label: '¿Tributa en otro país?', fieldName: 'Tributa_en_otro_pais__c', 
        type: 'text', initialWidth: 140
    }
];

export default class FormularioSeccionSARLAFTAcci extends LightningElement {
    @api recordId;
    @track data = [];
    columns = COLUMNS;
    isModalOpen = false;
    wiredResult;

    // Wire reactivo: se dispara cuando recordId tiene valor
    @wire(getShareholders, { caseId: '$recordId' })
    wiredShareholders(result) {
        this.wiredResult = result; 
        if (result.data) {
            // Transformamos los datos antes de asignarlos a this.data
            this.data = result.data.map(item => {
                return {
                    ...item,
                    de_Participacion__c: item.de_Participacion__c ? item.de_Participacion__c / 100 : 0
                };
            });
        } else if (result.error) {
            this.showToast('Error', 'No se pudieron cargar los socios', 'error');
        }
    }

    // Getter para ocultar/mostrar tabla
    get hasRecords() {
        return this.data && this.data.length > 0;
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Éxito',
                message: 'Registro creado correctamente',
                variant: 'success'
            })
        );
        this.closeModal();
        return refreshApex(this.wiredRecordsResult); // Refresca la tabla automáticamente
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    notifyDataChange() {
        this.dispatchEvent(new CustomEvent('formdataupdate', {
            detail: { data: { accionistas: this.shareholders } }
        }));
    }

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next', {
            detail: { data: { accionistas: this.shareholders } }
        }));
    }
}