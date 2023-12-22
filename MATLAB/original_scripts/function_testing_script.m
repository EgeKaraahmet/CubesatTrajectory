clear
clc

H = 200
T_e = 700



%% Standard Density 
    %Use bi-polynomial fit from Gill (1996)
    coeff=getCoeff(H,T_e)  %coefficient matrix
    if size(coeff) == [6, 5]; 
    % Continue with the loop
    else
        error('Coefficient matrix size is not as expected.');
    end

    logRho=0;
    for i=0:5
        for j=0:4
            logRho = logRho + coeff(i+1,j+1)*((H/1000)^i)*((T_e/1000)^j);
        end 
    end



 function c=getCoeff(Z,T)
    %Retrieve coefficients for bi-polynomial fit taken from Tables 3.9 and 3.10
    %of Satellite Orbits. These numbers were entered manually and may include
    %some typing errors. This should be replaced by the process described in
    %E. Gill, "Smooth Bi-Polynomial Interpolation of Jacchia 1971 Atmospheric
    %Densities For Efficient Satellite Drag Computation," DLR-GSOC IB 96-1,
    %German Aerospace Center (DLR), 1996
    %This paper is unavailable at this time.
    if Z<90 || Z>2500
        error('Z must be in range 90km < Z < 2500km')
    end
    if T<500 || T>1900
        error('T must be in range 500K < T < 1900K')
    end
    if T<850
        if Z<1000
            if Z<500
                if Z<180
                    c=[-0.3520856e2  0.3912622e1 -0.8649259e2  0.1504119e3 -0.7109428e2;
                        0.1129210e4  0.1198158e4  0.8633794e3 -0.3577091e4 -0.1970558e4;
                       -0.1527475e5 -0.3558481e5  0.1899243e5  0.2508241e5 -0.1968253e5;
                        0.9302042e5  0.3646554e6 -0.3290364e6 -0.1209631e5 0.8438137e5;
                       -0.2734394e6 -0.1576097e7  0.1685831e7 -0.4282943e6 -0.1345593e6;
                        0.3149696e6  0.2487723e7 -0.2899124e7  0.1111904e7 0.3294095e4];
                else
                    c=[ 0.2311910e2  0.1355298e3 -0.8424310e3  0.1287331e4 -0.6181209e3;
                       -0.1057776e4  0.6087973e3  0.8690566e4 -0.1715922e5 0.9052671e4;
                        0.1177230e5 -0.3164132e5 -0.1076323e4  0.6302629e5 -0.4312459e5;
                       -0.5827663e5  0.2188167e6 -0.2422912e6  0.2461286e5 0.6044096e5;
                        0.1254589e6 -0.5434710e6  0.8123016e6 -0.4490438e6 0.5007458e5;
                       -0.9452922e5  0.4408026e6 -0.7379410e6  0.5095273e6 -0.1154192e6];
                end
            else
                c=[-0.1815722e4  0.9792972e4 -0.1831374e5  0.1385255e5 -0.3451234e4;
                    0.9851221e4 -0.5397525e5  0.9993169e5 -0.7259456e5 0.1622553e5;
                   -0.1822932e5  0.1002430e6 -0.1784481e6  0.1145178e6 -0.1641934e5;
                    0.1298113e5 -0.7113430e5  0.1106375e6 -0.3825777e5 -0.1666915e5;
                   -0.1533510e4  0.7815537e4  0.7037562e4 -0.4674636e5 0.3516946e5;
                   -0.1263680e4  0.7265792e4 -0.2092909e5  0.2936094e5 -0.1491676e5];
            end
        else
            c=[ 0.3548698e3 -0.2508685e4  0.6252742e4 -0.6755376e4  0.2675763e4;
               -0.5370852e3  0.4182586e4 -0.1151114e5  0.1338915e5 -0.5610580e4;
               -0.2349586e2 -0.8941841e3  0.4417927e4 -0.6732817e4  0.3312608e4;
                0.3407073e3 -0.1531588e4  0.2179045e4 -0.8841341e3 -0.1369769e3;
               -0.1698470e3  0.8985697e3 -0.1704797e4  0.1363098e4 -0.3812417e3;
                0.2494943e2 -0.1389618e3  0.2820058e3 -0.2472862e3  0.7896439e2];
        end
    else 
        if Z<1000
            if Z<500
                if Z<180
                     c=[-0.5335412e2  0.2900557e2 -0.2046439e2  0.7977149e1 -0.1335853e1;
                         0.1977533e4 -0.7091478e3  0.4398538e3 -0.1568720e3 0.2615466e2;
                         -0.2993620e5  0.5187286e4 -0.1989795e4  0.3643166e3 -0.5700669e2;
                         0.2112068e6 -0.4483029e4 -0.1349971e5  0.9510012e4 -0.1653725e4;
                         -0.7209722e6 -0.7684101e5  0.1256236e6 -0.6805699e5 0.1181257e5;
                         0.9625966e6  0.2123127e6 -0.2622793e6  0.1337130e6 -0.2329995e5];
                else
                    c=[ 0.4041761e2 -0.1305719e3  0.1466809e3 -0.7120296e2 0.1269605e2;
                       -0.8127720e3  0.2273565e4 -0.2577261e4  0.1259045e4 -0.2254978e3;
                        0.5130043e4 -0.1501308e5  0.1717142e5 -0.8441698e4 0.1518796e4;
                       -0.1600170e5  0.4770469e5 -0.5473492e5  0.2699668e5 -0.4870306e4;
                        0.2384718e5 -0.7199064e5  0.8284653e5 -0.4098358e5 0.7411926e4;
                       -0.1363104e5  0.4153499e5 -0.4793581e5  0.2377854e5 -0.4310233e4];
                end
            else
                c=[-0.4021335e2 -0.1326983e3  0.3778864e3 -0.2808660e3 0.6513531e2;
                    0.4255789e3  0.3528126e3 -0.2077888e4  0.1726543e4 -0.4191477e3;
                   -0.1821662e4  0.7905357e3  0.3934271e4 -0.3969334e4 0.1027991e4;
                    0.3070231e4 -0.2941540e4 -0.3276639e4  0.4420217e4 -0.1230778e4;
                   -0.2196848e4  0.2585118e4  0.1382776e4 -0.2533006e4 0.7451387e3;
                    0.5494959e3 -0.6604225e3 -0.3328077e3  0.6335703e3 -0.1879812e3];
            end
        else 
            c=[ 0.1281061e2 -0.3389179e3  0.6861935e3 -0.4667627e3  0.1029662e3;
                0.2024251e3  0.1668302e3 -0.1147876e4  0.9918940e3 -0.2430215e3;
               -0.5750743e3  0.8259823e3  0.2329832e3 -0.6503359e3  0.1997989e3;
                0.5106207e3 -0.1032012e4  0.4851874e3  0.8214097e2 -0.6527048e2;
               -0.1898953e3  0.4347501e3 -0.2986011e3  0.5423180e2  0.5039459e1;
                0.2569577e2 -0.6282710e2  0.4971077e2 -0.1404385e2  0.8450500e0];
        end
    end
end