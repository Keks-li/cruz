-- Add product_id column to payments table
ALTER TABLE public.payments 
ADD COLUMN IF NOT EXISTS product_id bigint REFERENCES public.products(id);

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_payments_product_id ON public.payments(product_id);
