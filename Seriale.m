%% MATLAB CODE - LABORATORIO 2
clear variables;

%% NB!Impostare il corretto nome della porta com che si desidera usare
COMPORT_NAME = 'COM4';

%% Caricamento del file dell'immagine a colori
[file_load,path_load] = uigetfile('*.*');
if isequal(file_load,0)
   exit;
end

%% Creazione del vettore di byte da inviare
% matrice a 3 dimensioni dell'immagine a colori
color_image_matrix = imread(fullfile(path_load,file_load));

% numero di pixel in larghezza dell'immagine
image_x_pixel_count = size(color_image_matrix,1);
% numero di pixel in altezza dell'immagine
image_y_pixel_count = size(color_image_matrix,2);
% numero di pixel dell'immagine
image_pixel_count = image_x_pixel_count * image_y_pixel_count;

% numero di byte dell'immagine a colori
color_image_byte_count = image_pixel_count * 3;
% numero di byte dell'immagine in bianco nero
bw_image_byte_count = image_pixel_count;

% matrice a 3 dimensioni (una per colore) dell'immagine in bianco nero.
% tutte e tre le componenti verranno riempite con gli stessi dati
% elaborati dall'fpga
bw_image_matrix = zeros(image_x_pixel_count,image_y_pixel_count,3,'uint8');

% costruisco il vettore dei bytes r-g-b-r-g-b.. che compongono l'immagine a colori
color_image_vector = zeros(1,color_image_byte_count,'uint8');
color_image_vector(1:3:color_image_byte_count) = color_image_matrix(:,:,1);
color_image_vector(2:3:color_image_byte_count) = color_image_matrix(:,:,2);
color_image_vector(3:3:color_image_byte_count) = color_image_matrix(:,:,3);


%% Invio e ricezione dei dati
% istanzio la porta seriale e configuro i parametri
serial_com = serial(COMPORT_NAME);
serial_com.BaudRate = 115200;
serial_com.InputBufferSize = bw_image_byte_count;
serial_com.OutputBufferSize = color_image_byte_count;
serial_com.Timeout = 200;

% apro il canale di comunicazione
fopen(serial_com);
tic
% invio i dati dell'immagine a colori
fwrite(serial_com,color_image_vector);
% recupero i  dati dell'immagine in bianco nero
bw_image_vector = fread(serial_com);
% chiudo il canale di comunicazione ed elimono l'istanza della porta
toc
fclose(serial_com);
delete(serial_com);


%% Salvataggio del file dell'immagine in bianco nero risultante
% salvo i dati ricevuti nella matrice creata precedentemente
bw_image_matrix(:,:,1)=reshape(bw_image_vector,[image_x_pixel_count,image_y_pixel_count]);
bw_image_matrix(:,:,2)=bw_image_matrix(:,:,1);
bw_image_matrix(:,:,3)=bw_image_matrix(:,:,1);

[file_save,path_save] = uiputfile('*.png');
if isequal(file_save,0)
   exit;
end
imwrite(bw_image_matrix, fullfile(path_save,file_save));

%% Visualizzazione del risultato finale
figure, imshow(color_image_matrix);
figure, imshow(bw_image_matrix);
