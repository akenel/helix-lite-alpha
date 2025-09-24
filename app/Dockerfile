# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Install any needed packages specified in requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire contents of the 'backend' directory into the container's /app/backend directory
COPY ./backend/ ./backend/

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run the Uvicorn web server
# The correct syntax is module.file:app_object
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]