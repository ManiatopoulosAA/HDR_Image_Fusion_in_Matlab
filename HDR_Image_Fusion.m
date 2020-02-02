clear
clc

%user imputs
number_of_source_images=input('Specify number of source images. (3-7)');
while number_of_source_images>7||number_of_source_images<3
    number_of_source_images=input('Specify number of source images. (3-7)');
end

%code can work with 3 to 7 source images. 
%1 is darker and 3 (or 7) the brightest

answer=input('Do you want postprocessing? (Y/N)','s');
while answer~="Y"&&answer~="N"&&answer~="y"&&answer~="n"
    answer=input('Do you want postprocessing (Y/N)','s');
end

tic

if answer=="Y"||answer=="y"
    postprocessing=1;
else
    postprocessing=0;
end

A1=double(imread('1.jpg'));
A2=double(imread('2.jpg'));
A3=double(imread('3.jpg'));

[k,l,m]=size(A1);

AI=zeros(number_of_source_images,k,l);

A1=uint8(A1);
A2=uint8(A2);
A3=uint8(A3);

A1y=double(rgb2gray(A1));
A2y=double(rgb2gray(A2));
A3y=double(rgb2gray(A3));

All(1:k,1:l,1:3,1)=double(A1);
All(1:k,1:l,1:3,2)=double(A2);
All(1:k,1:l,1:3,3)=double(A3);

All_y(1:k,1:l,1)=double(A1y);
All_y(1:k,1:l,2)=double(A2y);
All_y(1:k,1:l,3)=double(A3y);

clear A1 A2 A3;

if number_of_source_images>3
    A4=double(imread('4.jpg'));
    A4=uint8(A4);
    A4y=double(rgb2gray(A4));
    All(1:k,1:l,1:3,4)=double(A4);
    All_y(1:k,1:l,4)=double(A4y);
    clear A4;
    if number_of_source_images>4
        A5=double(imread('5.jpg'));
        A5=uint8(A5);
        A5y=double(rgb2gray(A5));
        All(1:k,1:l,1:3,5)=double(A5);
        All_y(1:k,1:l,5)=double(A5y);
        clear A5;
        if number_of_source_images>5
            A6=double(imread('6.jpg'));
            A6=uint8(A6);
            A6y=double(rgb2gray(A6));
            All(1:k,1:l,1:3,6)=double(A6);
            All_y(1:k,1:l,6)=double(A6y);
            clear A6;
            if number_of_source_images>6
                A7=double(imread('7.jpg'));
                A7=uint8(A7);
                A7y=double(rgb2gray(A7));
                All(1:k,1:l,1:3,7)=double(A7);
                All_y(1:k,1:l,7)=double(A7y);
                clear A7;
            end
        end
    end
end

count=0;
x_train=zeros(1,5);
test=zeros(5,5);

value=zeros(number_of_source_images,1);
composed=zeros(1,(k-4)*(l-4));

%image_composer
A=3*ones(k,l);

for i=3:k-2
    for j=3:l-2
        
        count=count+1;
        for m=1:number_of_source_images
            test=All_y(i-2:i+2,j-2:j+2,m);
            x_train(1)=max(max(test))-min(min(test)); %contrast
            x_train(2)=std2(test); %standard deviation
            x_train(3)=abs(test(3,3)-mean(mean(test))); %likeness
            x_train(4)=abs(128-mean(mean(test)));
            x_train(5)=abs(128-test(3,3));
            
            value(m)=(x_train(1)*x_train(2)*x_train(3))/(x_train(4)*x_train(5)); %cost function
            if value(m)==max(value)
                g=m; %choose the best source image
            end
        end
        A(i,j)=g; %making the source matrix
    end
    clc
    fprintf('evaluating %d out of %d \n' , i-2, k-4); %progress tracing
    toc
end

% %bug cacher
for i=k
    for j=l:1
        if A(i,j)>number_of_source_images
            A(i,j)=number_of_source_images;
        end
        if A(i,j)<1
            A(i,j)=1;
        end
    end
end

%image_maker

A_cor=A;

for i=2:k-1
   for j=2:l-1
       test=A(i-1:i+1,j-1:j+1);
       A_cor(i,j)=round(mean(mean(test))); %remove salt and pepper noise
   end
end

sigma=ceil(k/100);
A_cor=double(imgaussfilt(A_cor,sigma)); %remove dark and light boundaries through source fusion

HDR=zeros(k,l,3);

for i=1:k
    for j=1:l
        temp=A_cor(i,j);
        flo=floor(temp);
        if flo<1 %bug catcher
            flo=1;
        end
        cei=ceil(temp);
        if cei>number_of_source_images %bug catcher
            cei=number_of_source_images;
        end
        HDR(i,j,:)=All(i,j,:,flo)*abs(cei-temp)+All(i,j,:,cei)*abs(temp-flo); %most info image maker
    end
end

%image_lightining

Im_enlight=double(HDR); %histogram normaliation

minim=min(min(min(Im_enlight)));
maxim=max(max(max(Im_enlight)));
if minim>0||maxim<255
    Im_enlight=Im_enlight-minim;
    min(min(min(Im_enlight)));
    
    Im_enlight=floor(Im_enlight.*(255/maxim));
    max(max(max(Im_enlight)));
    
    HDR_test=uint8(Im_enlight);
    imshow(HDR_test);
    
    imwrite(HDR_test, 'HDR_test.jpg');
end

HDR=uint8(HDR);
imshow(HDR); %image demostartion
imwrite(HDR, 'HDR_light.jpg'); %image with the most info

%Postprocessing
mean_A=mean(mean(A_cor));
a=((number_of_source_images+1)/2)/mean_A;

if a<1 %if image is too dark
    A_cor=A_cor-1; %normalization for eye
    A_cor=A_cor*a;
    A_cor=A_cor+1;
end

if a>1 %if image is too bright
    A_cor=A_cor(i,j)-number_of_source_images;
    A_cor=A_cor(i,j)/a;
    A_cor=A_cor+number_of_source_images;
end

HDR_impr=zeros(k,l,3);
for i=1:k
    for j=1:l
        temp=A_cor(i,j);
        flo=floor(temp);
        if flo<1 %bug catcher
            flo=1;
        end
        cei=ceil(temp);
        if cei>number_of_source_images  %bug catcher
            cei=number_of_source_images;
        end
        HDR_impr(i,j,:)=All(i,j,:,flo)*abs(cei-temp)+All(i,j,:,cei)*abs(temp-flo); %eye normalized image
    end
end

HDR_impr=uint8(HDR_impr);
if postprocessing==1
   HDR_impr=imsharpen(HDR_impr,'Radius',1,'Amount',1); %recover some edges
end

figure(2)
imshow(HDR_impr);
imwrite(HDR_impr, 'HDR_impr.jpg');
toc