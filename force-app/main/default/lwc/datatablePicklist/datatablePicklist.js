import { LightningElement, api } from 'lwc';

export default class DatatablePicklist extends LightningElement {
    @api label;
    @api placeholder;
    @api options = [];
    @api value;
    @api context;

    // Este es el cambio principal: calculamos el estado "selected" aquí
    get processedOptions() {
        const allOptions = this.options || [];
        
        return allOptions.map(opt => {
            return {
                ...opt,
                // Usamos String() en ambos para que '1' (string) sea igual a 1 (entero)
                // Esto evita errores si el dato cambia de tipo durante el renderizado
                isSelected: String(opt.value) === String(this.value)
            };
        });
    }

    handleChange(event) {
        this.dispatchEvent(new CustomEvent('picklistchanged', {
            composed: true,
            bubbles: true,
            detail: {
                value: event.target.value,
                context: this.context
            }
        }));
    }
}