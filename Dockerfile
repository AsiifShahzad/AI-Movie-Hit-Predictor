# AWS Lambda Python Base Image (RECOMMENDED)
FROM public.ecr.aws/lambda/python:3.13

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install Python dependencies
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

# Copy project files to Lambda task root
COPY project_components/ ${LAMBDA_TASK_ROOT}/project_components/
COPY validate.py ${LAMBDA_TASK_ROOT}/

# Set the Lambda handler
# Lambda will call: project_components.code.app.handler
CMD ["project_components.code.app.handler"]
