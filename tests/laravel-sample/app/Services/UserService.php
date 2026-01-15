<?php

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepositoryInterface;

/**
 * GOOD: Service class with dependency injection
 */
class UserService
{
    public function __construct(
        private UserRepositoryInterface $userRepository
    ) {}

    public function getAllUsers(): array
    {
        return $this->userRepository->all();
    }

    public function findUser(int $id): ?User
    {
        return $this->userRepository->find($id);
    }

    public function createUser(array $data): User
    {
        return $this->userRepository->create($data);
    }
}
