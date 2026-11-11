clc
close all

% Incarcam setul 3 de date.
nume_fisier = 'lab4_3.mat';
date_motor = load('lab4_3.mat', 'Ts', 't', 'u', 'vel');

perioada_esantionare = date_motor.Ts;
timp_masurat = date_motor.t(:);
semnal_intrare = date_motor.u(:);
viteza_motor = date_motor.vel(:);

numar_zero_initial = 10;
numar_date_identificare = 500;
numar_zero_pauza = 10;
numar_date_validare = 70;

primul_esantion_id = numar_zero_initial + 1;
ultimul_esantion_id = numar_zero_initial + numar_date_identificare;
primul_esantion_val = ultimul_esantion_id + numar_zero_pauza + 1;
ultimul_esantion_val = primul_esantion_val + numar_date_validare - 1;

indici_id = primul_esantion_id:ultimul_esantion_id;
indici_val = primul_esantion_val:ultimul_esantion_val;

figure
subplot(2,1,1)
plot(timp_masurat, semnal_intrare)
grid on
ylabel('Intrare')

subplot(2,1,2)
plot(timp_masurat, viteza_motor)
grid on
xlabel('Timp [s]')
ylabel('Viteza')

media_intrarii = mean(semnal_intrare(indici_id));
media_vitezei = mean(viteza_motor(indici_id));

disp(['Media intrarii: ', num2str(media_intrarii)])
disp(['Media vitezei: ', num2str(media_vitezei)])

intrare_centrata = semnal_intrare(indici_id) - media_intrarii;
viteza_centrata = viteza_motor(indici_id) - media_vitezei;
numar_esantioane_id = length(indici_id);

lungimi_fir = 10:10:100;
eroare_medie_patratica_identificare = zeros(length(lungimi_fir),1);
eroare_medie_patratica_validare = zeros(length(lungimi_fir),1);
ponderi_pentru_fiecare_M = cell(length(lungimi_fir),1);
iesiri_model_pentru_fiecare_M = cell(length(lungimi_fir),1);

for index_M = 1:length(lungimi_fir)
    lungime_fir = lungimi_fir(index_M);
    numar_corelatii = 3 * lungime_fir;

    corelatie_intrare = zeros(numar_corelatii,1);
    corelatie_viteza_intrare = zeros(numar_corelatii,1);

    for intarziere = 0:numar_corelatii-1
        corelatie_intrare(intarziere+1) = ...
            sum(intrare_centrata(1+intarziere:numar_esantioane_id) .* ...
            intrare_centrata(1:numar_esantioane_id-intarziere)) / ...
            numar_esantioane_id;

        corelatie_viteza_intrare(intarziere+1) = ...
            sum(viteza_centrata(1+intarziere:numar_esantioane_id) .* ...
            intrare_centrata(1:numar_esantioane_id-intarziere)) / ...
            numar_esantioane_id;
    end

    matrice_corelatii = zeros(numar_corelatii,lungime_fir);

    for index_rand = 1:numar_corelatii
        intarziere_corelatie = index_rand - 1;
        for index_pondere = 1:lungime_fir
            intarziere_fir = index_pondere - 1;
            matrice_corelatii(index_rand,index_pondere) = ...
                corelatie_intrare(abs(intarziere_corelatie - ...
                intarziere_fir) + 1);
        end
    end

    ponderi_fir = matrice_corelatii \ corelatie_viteza_intrare;
    intrare_deviatie = semnal_intrare - media_intrarii;
    viteza_estimata = media_vitezei + conv(intrare_deviatie, ponderi_fir);
    viteza_estimata = viteza_estimata(1:length(viteza_motor));

    ponderi_pentru_fiecare_M{index_M} = ponderi_fir;
    iesiri_model_pentru_fiecare_M{index_M} = viteza_estimata;
    eroare_medie_patratica_identificare(index_M) = mean(...
        (viteza_motor(indici_id) - viteza_estimata(indici_id)).^2);
    eroare_medie_patratica_validare(index_M) = mean(...
        (viteza_motor(indici_val) - viteza_estimata(indici_val)).^2);
end

figure
subplot(2,1,1)
plot(lungimi_fir, eroare_medie_patratica_identificare, 'o-')
grid on
xlabel('Lungimea FIR, M')
ylabel('Eroare medie patrata identificare')

subplot(2,1,2)
plot(lungimi_fir, eroare_medie_patratica_validare, 's-')
grid on
xlabel('Lungimea FIR, M')
ylabel('Eroare medie patrata validare')

% M = 60 este valoarea indicata pe tabla.
lungime_fir_aleasa = 60;
index_M_ales = find(lungimi_fir == lungime_fir_aleasa, 1);
ponderi_fir_ales = ponderi_pentru_fiecare_M{index_M_ales};
viteza_model_ales = iesiri_model_pentru_fiecare_M{index_M_ales};

disp(['Fisier: ', nume_fisier])
disp(['M ales: ', num2str(lungime_fir_aleasa)])
disp(['Eroare medie patrata identificare: ', num2str(eroare_medie_patratica_identificare(index_M_ales))])
disp(['Eroare medie patrata validare: ', num2str(eroare_medie_patratica_validare(index_M_ales))])

timp_real = timp_masurat - timp_masurat(1);
timp_echidistant = (0:length(viteza_motor)-1)' * perioada_esantionare;

figure
plot(timp_real, viteza_motor, '.')
hold on
plot(timp_echidistant, viteza_model_ales)
grid on
xlabel('Timp [s]')
ylabel('Viteza: masurata (puncte), model (linie)')

figure
stem((0:lungime_fir_aleasa-1) * perioada_esantionare, ...
    ponderi_fir_ales, 'filled')
grid on
xlabel('Intarziere [s]')
ylabel('Pondere FIR')

