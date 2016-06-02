function [desc1,desc2, ages] = ageMatch(descriptors1,descriptors2)

%    rng(1); % Initialize random generation to get repeatable results

   age1 = descriptors1.Age(:);
   age2 = descriptors2.Age(:);
   
   minAge = min([age1;age2]);
   maxAge = max([age1;age2]);
   
   lows  = minAge:10:maxAge;
   highs = lows + 10; 
   
   desc1 = [];
   desc2 = [];
   
   for k = 1:numel(lows)
       mskAge1 = (age1 >= lows(k)) & (age1 < highs(k));
       mskAge2 = (age2 >= lows(k)) & (age2 < highs(k));
       
       nSubj = min(sum(mskAge1), sum(mskAge2));
       
       if nSubj > 0
         % Get subsets for current bin  
         set1 = descriptors1(mskAge1,:);
         set2 = descriptors2(mskAge2,:);
         
         % shuffle patients 
         ix1  = randperm(size(set1,1));
         set1 = set1(ix1,:);
         
         ix2  = randperm(size(set2,1));
         set2 = set2(ix2,:);
         
         % Get equally sized subsets
         desc1 = [desc1; set1(1:nSubj,:)];
         desc2 = [desc2; set2(1:nSubj,:)];
         
       end
       
   end
   
   
   ages.set1.mean = mean(desc1.Age(:));
   ages.set1.std  = std(desc1.Age(:));
   
   ages.set2.mean = mean(desc2.Age(:));
   ages.set2.std  = std(desc2.Age(:));

end