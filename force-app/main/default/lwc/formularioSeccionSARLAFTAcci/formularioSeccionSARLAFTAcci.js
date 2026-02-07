import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import getShareholders from '@salesforce/apex/WizardArriendosController.getShareholders';
import createShareholder from '@salesforce/apex/WizardArriendosController.createShareholder';
const COLUMNS = [
    {
        label: 'Nombre del Cliente', fieldName: 'Nombre_del_Cliente__c',
        type: 'text', initialWidth: 230
    },
    {
        label: 'Tipo de documento', fieldName: 'Tipo_de_Documento__c',
        type: 'text', initialWidth: 150
    },
    {
        label: 'Nro documento', fieldName: 'Cedula_o_NIT__c',
        type: 'text', initialWidth: 150
    },
    {
        label: '% de Participación', fieldName: 'de_Participacion__c',
        type: 'percent', initialWidth: 150, typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '2'
        }, cellAttributes: { alignment: 'left' }
    },
    {
        label: '¿Cotiza en bolsa?', fieldName: 'Cotiza_en_bolsa__c',
        type: 'text', initialWidth: 140
    },
    {
        label: '¿Es PEP?', fieldName: 'Es_PEP__c',
        type: 'text', initialWidth: 100
    },
    {
        label: '¿Tributa en otro país?', fieldName: 'Tributa_en_otro_pais__c',
        type: 'text', initialWidth: 140
    }
];

export default class FormularioSeccionSARLAFTAcci extends LightningElement {
    @api recordId;
    @track shareholders = [];
    @track statusMessage = { text: '', variant: '', visible: false };
    columns = COLUMNS;
    @track isModalOpen = false;
    @track isLoading = false;
    wiredResult;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef) {
            const urlId = pageRef.state.recordId;
            if (urlId) {
                this.recordId = urlId;
            }
        }
    }

    @wire(getShareholders, { caseId: '$recordId' })
    wiredShareholders(result) {
        this.wiredResult = result;
        if (result.data) {
            this.shareholders = result.data.map(item => {
                return {
                    ...item,
                    de_Participacion__c: item.de_Participacion__c ? item.de_Participacion__c / 100 : 0
                };
            });
        } else if (result.error) {
            this.showStatus('No se pudieron cargar los socios', 'error');
        }
    }

    // Método para mostrar el mensaje internamente
    showStatus(text, variant) {
        this.statusMessage = {
            text: text,
            variant: variant === 'success' ? 'slds-theme_success' : 'slds-theme_error',
            visible: true
        };
        //Ocultar el mensaje después de 7 segundos
        setTimeout(() => { this.statusMessage.visible = false; }, 7000);
    }

    // Para cerrar el mensaje manualmente con la "X"
    hideStatus() {
        this.statusMessage.visible = false;
    }

    // Getter para ocultar/mostrar tabla
    get hasRecords() {
        return this.shareholders && this.shareholders.length > 0;
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleSuccess() {
        this.isLoading = false;
        this.showStatus('¡Accionista guardado exitosamente!', 'success');
        this.closeModal();
        return refreshApex(this.wiredResult);
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;

        const fields = event.detail.fields;
        
        const fieldsToSend = {
            ...fields,
            Caso_Relacionado__c: this.recordId
        };

        createShareholder({ fieldsMap: fieldsToSend })
            .then(() => {
                this.handleSuccess();
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    handleError(error) {
    this.isLoading = false;
    const message = error.body ? error.body.message : 'Error desconocido';
    const messagePanel = this.template.querySelector('lightning-messages');
    if (messagePanel) {
        messagePanel.setError(message); 
    } else {
        this.showStatus(message, 'error');
    }

    console.error('Error detallado de validación:', message);
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
        if (!this.hasRecords) {
            this.showStatus(
                'Es obligatorio registrar al menos un accionista antes de continuar.',
                'error'
            );
            return;
        }
        this.hideStatus();

        this.dispatchEvent(new CustomEvent('next', {
            detail: { data: { accionistas: this.shareholders } }
        }));
    }
}