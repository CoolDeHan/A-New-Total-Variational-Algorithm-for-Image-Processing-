function [x,t]=main_new2_ups(y,xref)
	
	Nbiter= 500;
	tau = 0.9/10;
	sigma = 0.9/10;
	mu = 1;
opD = @(x) cat(3,[diff(x,1,1);zeros(1,size(x,2))],[diff(x,1,2) zeros(size(x,1),1)], [[x(2:end,2:end) ; x(end,1:end-1)] x(:,end)]-x, [x(1,:); [x(1:end-1,2:end)  x(2:end,end)]]-x);
	opDadj = @(u) [zeros(1,size(u,2)); u(1:end-1,:,1)]-[u(1:end-1,:,1); zeros(1,size(u,2))]+...
    [zeros(size(u,1),1) u(:,1:end-1,2)]-[u(:,1:end-1,2) zeros(size(u,1),1)]+...
    [zeros(1,size(u,2));[zeros(size(u,1)-1,1) u(1:end-1,1:end-1,3)]]-[[u(1:end-1,1:end-1,3) zeros(size(u,1)-1,1)]; zeros(1,size(u,2))]+...
    [[zeros(size(u,1)-1,1) u(2:end,1:end-1,4)]; zeros(1,size(u,2))]-[zeros(1,size(u,2));[u(2:end,1:end-1,4) zeros(size(u,1)-1,1)]];
	
	prox_mu_sigma_g = @(t) t-bsxfun(@rdivide, t, max(sqrt(sum(t.^2,3))/(mu*sigma),1));

	x = prox_mu_tau_f(zeros(size(y)*2),y);
	u = zeros([size(x) 4]);
	v = zeros([size(x) 4 3]);
	tmp = opD(x);
	v(:,:,1,1) = tmp(:,:,1);
	v(:,:,2,2) = tmp(:,:,2);
	%fprintf('0 %f\n',sum(abs(tmp(:)))); % == sum(sum(sum(sqrt(sum(v.^2,3)))))
	for iter = 1:Nbiter
		x = prox_mu_tau_f(x+tau*opDadj(-opD(x)+opLadj(v)-mu*u),y);
		v = prox_mu_sigma_g(v-sigma*opL(-opD(x)+opLadj(v)-mu*u));
		u = u-(-opD(x)+opLadj(v))/mu;
% 		if mod(iter,40)==0
% 			%we display the primal and dual cost functions, which reach equal values at convergence
% 			tmp = opDadj(u);
% 			tmp = tmp(1:2:end,1:2:end)+tmp(2:2:end,1:2:end)+...
% 			tmp(1:2:end,2:2:end)+tmp(2:2:end,2:2:end);
% 			fprintf('%d %f %f\n',iter,sum(sum(sum(sqrt(sum(v.^2,3))))),...
% 				sum(sum(tmp.*y)));
% 			figure(3);
% 			imshow(x);
% 			colormap flag
% 			drawnow
% 		end
	end
% 	figure(3);
% 	imshow(x);
% 	colormap gray
% 	fprintf('||x-xref||=%f\n',norm(x-xref,'fro'));
%     v=norm(x-xref,'fro');
	
% 	figure(4)
% 	imshow(x);
% 	colormap gray
%      imwrite(x,'new2upbik.png');
  t=psnr(x,xref);
end


function xout = prox_mu_tau_f(x,y)
	z=y-(x(1:2:end,1:2:end)+x(2:2:end,1:2:end)+...
	x(1:2:end,2:2:end)+x(2:2:end,2:2:end))/4;
	xout = x;
	xout(1:2:end,1:2:end)=x(1:2:end,1:2:end)+z;
	xout(2:2:end,1:2:end)=x(2:2:end,1:2:end)+z;
	xout(1:2:end,2:2:end)=x(1:2:end,2:2:end)+z;
	xout(2:2:end,2:2:end)=x(2:2:end,2:2:end)+z;
end 

function t = opL(u)
	[height,width,d]=size(u);
	t=zeros(height,width,4,3);
    t(:,:,1,1)=u(:,:,1); 
	t(:,:,2,1)=(u(:,:,2)+...
        [zeros(height,1) u(:,1:end-1,2)]+...
        [u(2:end,:,2); zeros(1,width)]+...
        [[zeros(height-1,1) u(2:end,1:end-1,2)]; zeros(1,width)])/4; 
	t(:,:,3,1)=(u(:,:,3)+...
        [zeros(height,1) u(:,1:end-1,3)])/2;
    t(:,:,4,1)=([u(2:end,:,4); zeros(1,width)]+...
        u(:,:,4)+[[zeros(height-1,1) u(2:end,1:end-1,4)]; zeros(1,width)]+...
        [u(3:end,:,4); zeros(2,width)]+...
        [zeros(height,1) [u(3:end,1:end-1,4);zeros(2,width-1)]]+...
        [zeros(height,1) u(:,1:end-1,4)])/6;
    t(:,:,2,2)=u(:,:,2);
	t(:,:,1,2)=(u(:,:,1)+...
        [zeros(1,width);u(1:end-1,:,1)]+...
        [u(:,2:end,1) zeros(height,1)]+...
        [zeros(1,width);[u(1:end-1,2:end,1) zeros(height-1,1)]])/4; 
    t(:,:,3,2) = (u(:,:,3)+[zeros(1,width);u(1:end-1,:,3)])/2; 
    t(:,:,4,2)=(u(:,:,4)+[u(2:end,:,4); zeros(1,width)])/2;
    t(end,1:end-1,4,2)=(u(end,1:end-1,4))/2;
	t(:,:,1,3) = (u(:,:,1)+[zeros(1,width);u(1:end-1,:,1)])/2;
	t(:,:,2,3) = (u(:,:,2)+[zeros(height,1) u(:,1:end-1,2)])/2; 
    t(:,:,3,3) =1/4*(u(:,:,3)+...
        [zeros(1,width) ; u(1:end-1,:,3)]+...
        [zeros(height,1) u(:,1:end-1,3)]+...
        [zeros(1,width);...
         [zeros(height-1,1) u(1:end-1,1:end-1,3)]]);
  	t(:,:,4,3)=(u(:,:,4)+...
        [u(2:end,:,4); zeros(1,width)]+...
        [zeros(height,1) u(:,1:end-1,4)]+...
                [[zeros(height-1,1) u(2:end,1:end-1,4)]; zeros(1,width)])/4; 

    %-----------------------------------------------------------------------------------------------------------------
% 	t(:,:,1,1)=u(:,:,1);
% 	t(:,:,2,1)=([[zeros(height-1,1) u(2:end,1:end-1,2)]; zeros(1,width)]+...
%         [zeros(height,1) u(1:end,1:end-1,2)]+[u(2:end,1:end,2); zeros(1,width)]+u(:,:,2))/4; 		
%     t(1:end-1,1,2,1)=(u(1:end-1,1,2)+u(2:end,1,2))/4; 
% 	t(end,1:end,2,1)= 1/4*(u(end,1:end,2)+[0 u(end,1:end-1,2)]);
%     t(:,:,3,1)=1/2*(u(:,:,3)+[zeros(1,width) ; u(1:end-1,:,3)]); 
%     t(:,:,2,2)=u(:,:,2);
% 	t(:,:,1,2)=(u(:,:,1)+[zeros(1,width); u(1:end-1,1:end,1)]+[u(1:end,2:end,1) zeros(height,1)]+...
%         [zeros(1,width);[u(1:end-1,2:end,1) zeros(height-1,1)]])/4; 
% 	%t(1,1:end-1,1,2)=(u(1,1:end-1,1)+u(1,2:end,1))/4; 	
%     %t(1:end,end,1,2)= 1/4*(u(1:end, end,1)+[0 ;u(1:end-1,end,1)]);
%     t(:,:,3,2)=1/2*(u(:,:,3)+[zeros(height,1) u(:,1:end-1,3)]); 
%     t(:,:,1,3) = (u(:,:,1)+[zeros(1,width) ; u(1:end-1,:,1)])/2; 
% 	%t(1,:,1,3) = u(1,:,1)/2;
% 	t(:,:,2,3) = (u(:,:,2)+[zeros(height,1) u(:,1:end-1,2)])/2; 
% 	%t(:,1,2,3) = u(:,1,2)/2;
%     t(:,:,3,3) =1/4*(u(:,:,3)+[zeros(1,width) ; u(1:end-1,:,3)]+[zeros(height,1) u(:,1:end-1,3)]+[zeros(1,width);...
%         [zeros(height-1,1) u(1:end-1,1:end-1,3)]]);
%     t(:,:,1,4)=1/2*(u(:,:,1)+[u(1:end,2:end,1) zeros(height,1)]);
%     %t(:,end,1,4)=1/2*(u(:,end,1));
%     t(:,:,2,4)=1/2*(u(:,:,2)+[u(2:end,:,2); zeros(1,width)]);
%     %t(end,:,2,4)=1/2*(u(end,:,2));
%     t(:,:,3,4)=u(:,:,3);
    end

function u = opLadj(t)
	[height,width,d,c]=size(t);
	u=zeros(height,width,4);
		[height,width,d,c]=size(t);
	u(:,:,1)=t(:,:,1,1)+...
        (t(:,:,1,2)+...
        [t(2:end,:,1,2); zeros(1,width)]+...
	[zeros(height,1) t(:,1:end-1,1,2)]+...
    [[zeros(height-1,1) t(2:end,1:end-1,1,2)];zeros(1,width)])/4+...
    (t(:,:,1,3)+[t(2:end,:,1,3); zeros(1,width)])/2;

u(:,:,2)=t(:,:,2,2)+...
    (t(:,:,2,1)+...
    [t(:,2:end,2,1) zeros(height,1)]+...
	[zeros(1,width); t(1:end-1,:,2,1)]+...
    [zeros(1,width); [t(1:end-1,2:end,2,1) zeros(height-1,1)]])/4+...
    (t(:,:,2,3)+[t(:,2:end,2,3) zeros(height,1)])/2;
    u(:,:,3)=(t(:,:,3,1)+...
        [t(:,2:end,3,1) zeros(height,1)])/2+...
     (t(:,:,3,2)+...
     [t(2:end,:,3,2); zeros(1,width)])/2+...
     (t(:,:,3,3)+...
     [t(2:end,:,3,3); zeros(1,width)]+...
     [t(:,2:end,3,3) zeros(height,1)]+...
     [[t(2:end,2:end,3,3) zeros(height-1,1)]; zeros(1,width)])/4;
 u(:,:,4)=1/6*(t(:,:,4,1)+[zeros(1,width); t(1:end-1,:,4,1) ]+...
     [[zeros(1,width-1); t(1:end-1,2:end,4,1)] zeros(height,1)]+...
     [zeros(2,width); t(1:end-2,:,4,1)]+...
     [zeros(2,width);[t(1:end-2,2:end,4,1) zeros(height-2,1)]]+...
     [t(:,2:end,4,1) zeros(height,1)])+...
     1/2*(t(:,:,4,2)+[zeros(1,width); t(1:end-1,:,4,2)])+...
     1/4*(t(:,:,4,3)+[zeros(1,width); t(1:end-1,:,4,3)]+...
     [ t(:,2:end,4,3) zeros(height,1)]+...
     [ [zeros(1,width-1); t(1:end-1,2:end,4,3)] zeros(height,1)]);
end