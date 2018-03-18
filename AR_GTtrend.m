% Load Data 
data = csvread('/Users/mueric35/Desktop/Sentiment-and-Marktet-Analysis/GTdata/s_p.csv',1,1);

% set Y
Y = data(:,1)';
Y = Y - mean(Y);
% set regressor 
X = data(:,[2,3,4])';

% set Timeframe
T = 170;

% set trend:
% trend: 
Ftrend=[1];
Gtrend=[1];
  % Ftrend=[1 0]'; Gtrend=[[1 1];[0 1]]; 
ntrend=length(Ftrend); 
itrend=1:ntrend;

% set Regressors
% regn:
q = 3; 

Fregn=zeros(1,q)'; 
Gregn = eye(q); 
nregn=q;
iregn=ntrend+1:ntrend+q;

% set seasonal pattarn
% Fourier components of seasonal:
p= 52; rseas=[1 3];
pseas=length(rseas); 
nseas=2*pseas; 
iseas=ntrend+nregn+1:ntrend+nregn+nseas; 
Fseas=repmat([1 0],1,pseas)'; 
Gseas = zeros(nseas,nseas); 

for j=1:pseas
       c=cos(2*pi*rseas(j)/p); 
       s=sin(2*pi*rseas(j)/p);
       i=2*j-1:2*j; 
       Gseas(i,i)=[[c s];[-s c]];
end

% AR component:
nar = 1; iar= (ntrend+nregn+nseas+1):ntrend+nregn+nseas+nar;
[phi B e enu sv] = ar((Y-mean(Y))',nar); phi=phi(1:nar); 
     % crude but informed starting value for AR coeff vector
Far=[1 zeros(1,nar-1)]'; Gar =  [ phi' ; [ eye(nar-1) zeros(nar-1,1)] ];


% DLM matrices F & G: 
F = [Ftrend;Fregn;Fseas;Far];
n=length(F); 
G = blkdiag(Gtrend,Gregn,Gseas,Gar); 
   
% priors p(\theta_1,v|D_0) & 3 discount factors for component DLMs: 
nu=90; S=0.15^2; 
%a=[0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1]';
a = repmat(0.1,n,1);

%R=blkdiag(0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1, 2.1067*eye(nseas)); 
R = eye(n)/10;
deltrend=0.9; delregn=0.99; delseas=0.95; delvar=0.99; delar = 0.8; 

%   Trend innovations variance U(1,1), AR innovations variance U(2,2)
    %nuv=5; sv=nuv*0.5; nuw=4; sw=nuw*.0001; nuar=4; swar=nuar*0.02; 
    nuv=10; sv=nuv*0.1; nuw=50; sw=nuw*.0001; nuar=10; swar=nuar*.0001; 
% V and DLM matrix W - initial value of top left 2x2 block, all rest is zero:
    V=sv/nuv; U=[[sw/nuw 0 0 0];[0 swar/nuar 0 0];[0 0 swar/nuar 0];[0 0 0 1]];
    V0 = V; 
    U0 = U; 
    ievo= [1, 5, 7 , 9];


% storage arrays for filtering summaries: 
sm=zeros(n,T); 
sa=zeros(n,T); 
sC=zeros(n,n,T);
sR=zeros(n,n,T); 
sf=zeros(1,T); 
sQ=zeros(1,T);
sS=zeros(1,T); 
snu=zeros(1,T); 
mlik=zeros(1,T); % to save the t densities at each point that give the model marginal likelihood

% now analysis ...
for t=1:T
    if (t>1) a = G*m; 
             R = G*C*G';  
             R(itrend,itrend)=R(itrend,itrend)/deltrend;  
             R(iregn,iregn)=R(iregn,iregn)/delregn; 
             R(iseas,iseas)=R(iseas,iseas)/delseas;
             nu=delvar*nu;% discount variance dof
    end
    Fregn=X(:,t)'; F(iregn)=Fregn; A = R*F; Q=F'*A + V; A=A/Q; f=F'*a;   
    y = Y(:,t);  
    % updating equations: 
        e=y-f; rQ=sqrt(Q); 
        mlik(t) = tpdf(e/rQ,nu)/rQ;
        r=(nu+e^2/Q)/(nu+1);
        m = a+A*e; C = r*(R-A*A'*Q); 
        nu=nu+1; S=r*S;  
    % save posterior at time t:
        sm(:,t)=m; sC(:,:,t)=C; sa(:,t)=a; sR(:,:,t)=R; sf(t)=f; sQ(t)=Q; sS(t)=S; snu(t)=nu;
        
end


% backward smoothing for retrospection - n.b. overwrites saved information
% first save filtered summaries for later backward sampling below: 
Sm=sm; SC=sC; SR=sR;  Sa=sa; SS=sS; Snu=snu; 
% then perform backward (Viterbi style) updating - overwriting
%  online posterior summaries at each time point with full posteriors: 
C=sC(:,:,T); St=sS(T); nu=snu(T); 
for t=T-1:-1:1
    B         = sC(:,:,t)*G'*inv(sR(:,:,t+1));              
    sm(:,t)   = sm(:,t)+B*(sm(:,t+1)-sa(:,t+1));        
    C         = sC(:,:,t)+B*(C-sR(:,:,t+1))*B';  
    St        = (1-delvar)/sS(t)+delvar/St; St=1/St; SS(t)=St; 
    nu        = (1-delvar)*snu(t)+delvar*nu; Snu(t)=nu; 
    sC(:,:,t) = C*St/sS(t);
end
% posterior quantile of time T final posterior t distribution:         
% vector of quantiles of posterior t distributions at each time: 
sq=qt(.95,snu);

% plot 1-step forecasting and error summaries over time
    figure(1); clf   
    subplot(2,1,1)
    h=sqrt(sQ).*sq; ciplot(sf-h,sf+h,1:T,[.85 .85 .85]); hold on
    plot(1:T,sf,'b',1:T,Y,'r+');
    title('90% prediction intervals and 1-step forecasts'); ylabel('boom town sv')
    subplot(2,1,2)
    ciplot(-sq,+sq,1:T,[.85 .85 .85]); hold on
    plot(1:T,(Y-sf)./sqrt(sQ),'r+'); plot([0 T+1],[0 0],'k:');
    title('90% prediction intervals and standardized 1-step errors'); ylabel('S&P 500 return')  
    
% posterior quantile of time T final posterior t distribution:             
sq=qt(.95,snu(T));

name = ["1","2","3"]

% plot smoothed/retrospective estimates and intervals for dynamic regn coeff: 
figure(2); clf
for k = 1:q
    subplot(3,1,k)
    h=sqrt(squeeze(sC(iregn(k),iregn(k),:)))'.*sq; ciplot(sm(iregn(k),:)-h,sm(iregn(k),:)+h,1:T,[.85 .85 .85]); hold on
    plot(1:T,sm(iregn(k),:),'b-'); hold off
    title('90% smoothed posterior intervals for Index regn '); ylabel(name(k))
    % plot smoothed/retorspective estimates and intervals for harmonic seasonal components:   
end

% plot seasonal 
figure(5); clf
for j=1:pseas
    i=iseas(2*j-1); 
    subplot(pseas,1,j)
    h=sqrt(squeeze(sC(i,i,:)))'*sq; ciplot(sm(i,:)-h,sm(i,:)+h,1:T,[.85 .85 .85]); hold on
    plot(1:T,sm(i,:),'b-');  plot([0 T+1],[0 0],'k:'); hold off
    title(['90% smoothed posterior intervals for harmonic ',int2str(rseas(j))]); ylabel('Harmonic')
end



