import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CheckboxSectionEditor extends OmniscriptBaseMixin(LightningElement) {
    @api recordId;
    @api checkboxesData;
    @api responseNode;
    @api isFromProductCatalog = false;

    checkboxes = [];
    isModalOpen = false;
    isFullscreen = false;
    editingId = null;
    modalContent = '';
    title = 'Secciones Adicionales';
    @track isOpen = true;
    @track isReadOnlyModal = false;

    get iconName() {
        return this.isOpen ? 'utility:switch' : 'utility:chevronright';
    }

    get modalTitle() {
        return this.isReadOnlyModal ? 'Vista de Sección' : 'Editar Sección';
    }

    get modalClass() {
        return `slds-modal ${this.isFullscreen ? 'fullscreen-modal' : 'slds-modal_large'} slds-fade-in-open`;
    }

    get groupedCheckboxes() {
        const grouped = [];
        let currentCategory = undefined;

        this.checkboxes.forEach(item => {
            const categoria = item.Categoria;

            if (categoria && categoria !== currentCategory) {
                grouped.push({ isHeader: true, label: categoria });
                currentCategory = categoria;
            } else if (!categoria && currentCategory !== null) {
                currentCategory = null;
            }

            grouped.push({ isCheckbox: true, data: item });
        });

        return grouped;
    }

    toggleSection() {
        this.isOpen = !this.isOpen;
    }

    connectedCallback() {
        if (this.checkboxesData && this.checkboxes.length === 0) {
            this.checkboxes = JSON.parse(JSON.stringify(this.checkboxesData));
            this.checkboxes.forEach(item => {
                if (item.RTB_descripcion) {
                    item.RTB_descripcion = item.RTB_descripcion;
                } else if (item.RBT_descripcion) {
                    item.RTB_descripcion = item.RBT_descripcion;
                } else if (item.descripcion) {
                    item.RTB_descripcion = item.descripcion;
                }

                if (item.id && typeof item[`IF_${item.id}`] === 'undefined') {
                    item[`IF_${item.id}`] = item.seleccionado || false;
                }

                if (!item.dynamicValues && item.RTB_descripcion) {
                    const tmp = document.createElement('div');
                    tmp.innerHTML = item.RTB_descripcion;
                    const inputs = tmp.querySelectorAll('input.inline-input');
                    const defaults = {};
                    inputs.forEach((input, idx) => {
                        const field = input.dataset.field || `field_${idx}`;
                        defaults[field] = input.getAttribute('value') || '';
                    });
                    if (Object.keys(defaults).length > 0) {
                        item.dynamicValues = defaults;
                        Object.keys(defaults).forEach(k => (item[k] = defaults[k]));
                    }
                }
            });

            if (this.isFromProductCatalog) {
                this.invokeIntegrationProcedure();
            }
        }
    }

    handleCheckboxChange(event) {
        const changedId = event.target.dataset.id;
        const isChecked = event.target.checked;
        const checkbox = this.checkboxes.find(c => c.id === changedId);
        if (checkbox) {
            checkbox.seleccionado = isChecked;
            checkbox[`IF_${changedId}`] = isChecked;
            this.invokeIntegrationProcedure();
        }
    }

    openModal(event) {
        this.editingId = event.target.dataset.id;
        const selected = this.checkboxes.find(c => c.id === this.editingId);
        if (!selected) return;

        this.modalContent = selected.RTB_descripcion || '';
        this.isModalOpen = true;
        this.isFullscreen = false;
        this.isReadOnlyModal = false;

        requestAnimationFrame(() => {
            const container = this.template.querySelector('.editable-content');
            if (!container) return;
            container.innerHTML = this.modalContent;

            const inputs = container.querySelectorAll('input.inline-input');
            inputs.forEach(input => {
                const field = input.dataset.field;
                if (selected.dynamicValues && selected.dynamicValues[field] !== undefined) {
                    input.value = selected.dynamicValues[field];
                }
            });
        });
    }

    openViewModal(event) {
        this.editingId = event.target.dataset.id;
        const selected = this.checkboxes.find(c => c.id === this.editingId);
        if (!selected) return;

        this.modalContent = selected.RTB_descripcion || '';
        this.isModalOpen = true;
        this.isFullscreen = false;
        this.isReadOnlyModal = true;

        requestAnimationFrame(() => {
            const container = this.template.querySelector('.readonly-content');
            if (!container) return;
            container.innerHTML = this.modalContent;
        });
    }

    closeModal() {
        this.isModalOpen = false;
        this.modalContent = '';
        this.editingId = null;
        this.isFullscreen = false;
        this.isReadOnlyModal = false;
    }

    toggleFullscreen() {
        this.isFullscreen = !this.isFullscreen;
    }

    collectAndRebuildHTML() {
        const container = this.template.querySelector('.editable-content');
        if (!container) return { html: this.modalContent, values: {} };

        const clone = container.cloneNode(true);
        const values = {};
        clone.querySelectorAll('input.inline-input').forEach((input, idx) => {
            const field = input.dataset.field || `field_${idx}`;
            const val = (input.value || '').trim();
            values[field] = val;
            input.setAttribute('value', val);
        });

        return { html: clone.innerHTML, values };
    }

    saveModalContent() {
        if (!this.editingId) {
            this.closeModal();
            return;
        }

        const { html: updatedHtml, values } = this.collectAndRebuildHTML();
        const checkbox = this.checkboxes.find(c => c.id === this.editingId);
        if (checkbox) {
            checkbox.RTB_descripcion = updatedHtml;
            checkbox.dynamicValues = values;
            Object.keys(values).forEach(key => {
                checkbox[key] = values[key];
            });
        }

        this.closeModal();
        this.invokeIntegrationProcedure();
    }

    invokeIntegrationProcedure() {
        const transformedCheckboxes = this.checkboxes.map(item => {
            const copy = { ...item };

            if ('RTB_descripcion' in copy) {
                copy.RBT_descripcion = copy.RTB_descripcion;
                delete copy.RTB_descripcion;
            }

            if (!item.dynamicValues && item.RTB_descripcion) {
                const tmp = document.createElement('div');
                tmp.innerHTML = item.RTB_descripcion;
                const inputs = tmp.querySelectorAll('input.inline-input');
                const defaults = {};
                inputs.forEach((input, idx) => {
                    const field = input.dataset.field || `field_${idx}`;
                    defaults[field] = input.getAttribute('value') || '';
                });
                if (Object.keys(defaults).length > 0) {
                    item.dynamicValues = defaults;
                }
            }

            if (item.dynamicValues) {
                copy.DynamicValues__c = JSON.stringify(item.dynamicValues);
            }

            return copy;
        });

        const inputParams = {
            data: {
                SlipId: this.recordId,
                [this.responseNode]: transformedCheckboxes
            }
        };

        const options = { chainable: false, useFuture: false };
        const ipConfig = {
            sClassName: 'IntegrationProcedureService',
            sMethodName: 'Slip_ActualizarSlip',
            input: inputParams,
            options: JSON.stringify(options)
        };

        this.omniRemoteCall(ipConfig, true)
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Slip actualizado',
                    message: '',
                    variant: 'success'
                }));
            })
            .catch(error => console.error('Error al ejecutar IP:', error));
    }
}